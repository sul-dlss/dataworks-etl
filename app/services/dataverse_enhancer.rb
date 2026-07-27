# frozen_string_literal: true

# Add related publications for a dataset from Dataverse if applicable
class DataverseEnhancer
  DATAVERSE_URL_PREFIX = "https://"
  def initialize(mapped_record:, doi:)
    @mapped_record = mapped_record
    @doi = doi
    @client = Clients::Dataverse.new(api_token: Settings.dataverse.api_token)
    @dataverse_record = @client.dataset_doi(doi: @doi) if check_dataverse?
  rescue Clients::Error => e
    # We do not want Honeybadger notifications if a particular
    # enhancement fails
    Rails.logger.error { "Dataverse retrieval error for #{@doi}, #{e}" }
  end

  # Should we get additional metadata
  def check_dataverse?
    @doi.present? && @mapped_record['url'].start_with?('https://dataverse.harvard.edu')
  end

  def add_metadata
    return @mapped_record unless @dataverse_record.present?

    add_publications_metadata
    
  rescue Clients::Error => e
    # Log any error that might occur with the client, then return the record
    # un-enhanced so the transform continues (Honeybadger.notify returns a String,
    # so it must not be the last expression).
    error_msg = "Dataverse metadata enhancement client error, #{e}"
    Rails.logger.error { error_msg }
    Honeybadger.notify(error_msg)
    @mapped_record
  end

  def add_publications_metadata
    # Extract related identifiers and titles for related publications
    # Add these to the record and return
    extract_publications
    @mapped_record
  end

  def extract_publications
    citation_fields = @dataverse_record.dig('data', 'latestVersion', 'metadataBlocks', 'citation', 'fields')
    # If this path doesn't exist or if the fields array is blank, return
    return [] if citation_fields.blank?

    publication_fields = citation_fields.filter_map do |field|
      field if field['typeName'] == 'publication'
    end

    

    publication_fields.filter_map do |publication_field|
      # We can map EITHER to a related item with title and a URL
      # OR to a related identifier with DOI
      id_type = publication_field.dig('publicationIDType', 'value')
      id_number = publication_field.dig('publicationIDNumber', 'value')
      title = publication_field.dig('publicationCitation', 'value')
      if id_type.present? && id_type.downcase == 'doi'
        
      else
        nil
      end
    end
  end
end
