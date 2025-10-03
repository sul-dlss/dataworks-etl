# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents for a single dataset
class MetadataCleaner
  # Fields for cleanup
  FIELDS = %w[creators_ssim contributors_ssim funders_ssim subjects_ssim publisher_ssi].freeze

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
      solr_doc[field] = cleanup_field(solr_doc[field]) if solr_doc.key?(field)
    end
    solr_doc
  end

  # Pass in an array of values for a field and clean up each value
  def cleanup_field(values)
    values = [values] unless values.is_a?(Array)
    delim = quote_delimited(values)
    titleized = delim.map(&:titleize)
    trimmed = titleized.map { |val| val.delete_prefix('(').delete_suffix(')').strip }

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
end
