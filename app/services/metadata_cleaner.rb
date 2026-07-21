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

  # Pass in an array of values for a field and clean up each value
  # Cleanup: Split out string of subjects into individual subjects;
  # remove opening and closing parentheses; remove leading or trailing spaces.
  def cleanup_field(field, values)
    values = [values] unless values.is_a?(Array)
    delim = quote_delimited(values)
    delim = semicolon_delimited(delim) if AUTHOR_FIELDS.include?(field)
    delim = subject_delimited(delim) if field == 'subjects_ssim'
    trimmed = delim.map { |val| unwrap_parens(val) }
    trimmed = trimmed.uniq if field == 'subjects_ssim'

    values.is_a?(Array) ? trimmed : trimmed[0]
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
