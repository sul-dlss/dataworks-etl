# frozen_string_literal: true

# Normalizes the affiliations on creators and contributors in a DataWorks
# metadata record. Runs on the dataworks metadata before Solr mapping, so the
# result flows to BOTH the flat affiliation fields (affiliation_names_sim) and the
# JSON struct fields (creators_struct_ss/contributors_struct_ss) the show page renders.
#
# Two jobs:
#
#   1. Strip markup / decode HTML entities from each affiliation name, so e.g.
#      "King&apos;s College London" no longer displays with a literal entity.
#   2. Split an affiliation whose name packs several institutions into a single
#      semicolon-delimited string, but ONLY when the affiliation has no
#      identifier, so an identifier such as a ROR is never mis-attached to an
#      institution it does not describe.
class AffiliationNormalizer
  # Record fields whose entries carry affiliations.
  ENTITY_FIELDS = %w[creators contributors].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(mapped_record:)
    @mapped_record = mapped_record.with_indifferent_access
  end

  # @return [ActiveSupport::HashWithIndifferentAccess] record with affiliations normalized
  def call
    ENTITY_FIELDS.each do |field|
      Array(@mapped_record[field]).each do |entry|
        next unless entry.is_a?(Hash) && entry['affiliation'].present?

        entry['affiliation'] = Array(entry['affiliation']).flat_map { |affiliation| normalize(affiliation) }
      end
    end
    @mapped_record
  end

  private

  # @return [Array<Hash>] one or more affiliations derived from the given one
  def normalize(affiliation)
    name = MarkupNormalizer.to_text(affiliation['name'])
    return [affiliation.merge('name' => name)] unless splittable?(affiliation, name)

    name.split(';').map(&:strip).compact_blank.map { |part| { 'name' => part } }
  end

  # Split only when the name carries a delimiter and there is no identifier that a
  # split would strand on the wrong institution.
  def splittable?(affiliation, name)
    name.present? && name.include?(';') && affiliation['affiliation_identifier'].blank?
  end
end
