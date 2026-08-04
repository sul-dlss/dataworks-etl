# frozen_string_literal: true

# Enhances a DataWorks schema metadata record based on the metadata on that record and related sources
class MetadataEnhancer
  def self.call(...)
    new(...).call
  end

  def initialize(mapped_record:, doi:)
    @mapped_record = mapped_record.with_indifferent_access
    @doi = doi
  end

  # @return enhanced metadata record for the dataset with additional metadata
  def call
    @mapped_record = enhance_with_stanford_data
    @mapped_record = enhance_with_openalex
    @mapped_record = enhance_with_dataverse
    @mapped_record
  end

  # Enhance with OpenAlex information
  def enhance_with_openalex
    OpenalexEnhancer.new(mapped_record: @mapped_record, doi: @doi).add_metadata
  end

  # Enhance with RIALTO author information
  def enhance_with_stanford_data
    StanfordEnhancer.new(mapped_record: @mapped_record).add_stanford_authors
  end

  # Enhance with Dataverse publications
  def enhance_with_dataverse
    enhanced_record = DataverseEnhancer.new(mapped_record: @mapped_record, doi: @doi).add_metadata

    mapped_length = @mapped_record['related_identifiers']&.length || 0
    enhanced_length = enhanced_record['related_identifiers']&.length || 0
    if mapped_length < enhanced_length
      Rails.logger.info("Dataverse provided additional identifiers for #{@doi}")
      Rails.logger.info(enhanced_record['related_identifiers'])
    end
    enhanced_record
  end
end
