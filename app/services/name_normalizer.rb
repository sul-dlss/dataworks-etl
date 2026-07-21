# frozen_string_literal: true

# Strips markup (raw or entity-encoded HTML) from creator and contributor names in
# a DataWorks metadata record, while preserving literal characters such as
# ampersands. Runs on the dataworks metadata before Solr mapping, so the cleaned
# name flows to BOTH the flat name fields (creators_ssim/contributors_ssim) and the
# JSON struct fields (creators_struct_ss/contributors_struct_ss).
class NameNormalizer
  # Name fields to normalize.
  NAME_FIELDS = %w[creators contributors].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(mapped_record:)
    @mapped_record = mapped_record.with_indifferent_access
  end

  # @return [ActiveSupport::HashWithIndifferentAccess] record with names normalized
  def call
    NAME_FIELDS.each do |field|
      Array(@mapped_record[field]).each do |entry|
        next unless entry.is_a?(Hash) && entry['name'].present?

        entry['name'] = MarkupNormalizer.to_text(entry['name']).presence
      end
    end
    @mapped_record
  end
end
