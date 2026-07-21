# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents for a single dataset
class MetadataCleaner
  # Fields for cleanup
  FIELDS = %w[creators_ssim contributors_ssim funders_ssim subjects_ssim publisher_ssi].freeze
  AUTHOR_FIELDS = %w[creators_ssim contributors_ssim].freeze
  # Trailing vocabulary-scheme acronym appended to a subject term, e.g. ":GCMD".
  SUBJECT_SCHEME_SUFFIX = /\s*:\s*[A-Z][A-Z0-9]{2,}\z/

  def self.call(...)
    new(...).call
  end

  def initialize(solr_doc:)
    @solr_doc = solr_doc&.with_indifferent_access
  end

  # @return [Hash] Solr document for the dataset.
  def call
    cleanup_fields(@solr_doc)
  end

  def cleanup_fields(solr_doc)
    FIELDS.each do |field|
      solr_doc[field] = cleanup_field(field, solr_doc[field]) if solr_doc.key?(field)
    end
    solr_doc
  end

  # Clean up a field's values and return them as a de-duplicated array:
  # split combined strings into individual values, strip wrapping parentheses
  # and whitespace from each, then de-duplicate.
  def cleanup_field(field, values)
    values = split_values(field, Array.wrap(values))
    values = values.map { |value| unwrap_parens(value) }
    values.uniq
  end

  # Split combined strings into individual values. Every field splits embedded
  # quoted, comma-separated strings; author fields also split on ";"; subjects
  # split on their ">" hierarchy.
  def split_values(field, values)
    values = quote_delimited(values)
    values = semicolon_delimited(values) if AUTHOR_FIELDS.include?(field)
    values = subject_delimited(values) if field == 'subjects_ssim'
    values
  end

  def quote_delimited(values)
    return_values = []

    values.each do |value|
      if value.include?('"') && value.include?(',')
        values_extracted = value.delete_prefix('"').delete_suffix('"').split('",')
        values_extracted.each do |value_extracted|
          return_values << value_extracted.delete_prefix('"').delete_suffix('"')
        end
      else
        return_values << value
      end
    end

    return_values
  end

  # Values may also be split out by semicolons for authors
  def semicolon_delimited(values)
    values.flat_map { |value| value.split(';').map(&:strip) }
  end

  # GCMD-style subjects encode a hierarchy with ">" (raw or entity-encoded) and
  # sometimes append a scheme acronym like ":GCMD"; markup such as <i> may also
  # appear. Strip markup, split the hierarchy into terms, drop the scheme suffix,
  # and remove blanks.
  def subject_delimited(values)
    values.flat_map do |value|
      MarkupNormalizer.to_text(value).split('>').map { |term| term.sub(SUBJECT_SCHEME_SUFFIX, '') }
    end.map(&:strip).compact_blank
  end

  # Strip a pair of parentheses only when they wrap the whole value with nothing
  # nested, so a trailing acronym such as "(PNG)" keeps its closing parenthesis.
  def unwrap_parens(value)
    stripped = value.strip
    stripped.match?(/\A\([^()]*\)\z/) ? stripped[1...-1].strip : stripped
  end
end
