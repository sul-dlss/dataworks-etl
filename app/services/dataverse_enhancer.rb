# frozen_string_literal: true

# Add related publications for a dataset from Dataverse if applicable
class DataverseEnhancer
  DATAVERSE_URL_PREFIX = 'https://dataverse.harvard.edu'
  RETAIN_CASE_TYPES = %w[arXiv bibcode DASH-NRS handle pmid].freeze

  def initialize(mapped_record:, doi:)
    @mapped_record = mapped_record
    @doi = doi
    @client = Clients::Dataverse.new(api_token: Settings.dataverse.api_token)
    @related_identifiers = map_record_related_identifiers
    @dataverse_record = @client.dataset_doi(doi: @doi) if check_dataverse?
  rescue Clients::Error => e
    # We do not want Honeybadger notifications if a particular
    # enhancement fails
    Rails.logger.error { "Dataverse retrieval error for #{@doi}, #{e}" }
  end

  # Should we get additional metadata
  def check_dataverse?
    @doi.present? && @mapped_record['url'].start_with?(DATAVERSE_URL_PREFIX)
  end

  def add_metadata
    return @mapped_record if @dataverse_record.blank?

    add_publications_metadata
  end

  def add_publications_metadata
    # Extract related identifiers and titles for related publications
    # Add these to the record and return
    related_publications = extract_publications
    if related_publications.size.positive?
      # If array entry didn't exist, create it
      @mapped_record['related_identifiers'] = [] if @mapped_record['related_identifiers'].blank?
      # Concat whatever publications we do have to these
      @mapped_record['related_identifiers'].concat(related_publications)
    end
    @mapped_record
  end

  # Extract the identifiers of related publications
  def extract_publications
    citation_fields = @dataverse_record.dig('data', 'latestVersion', 'metadataBlocks', 'citation', 'fields')
    # If this path doesn't exist or if the fields array is blank, return
    return [] if citation_fields.blank?

    # publication_field from the Dataverse metadata is of the form:
    # {"typeName" => "publication",  "value" => [
    # {"publicationIDNumber" => {"value" => "x"}, "publicationIDType" => {"value" => "y"},
    # "publicationRelationType" = {"value" => "z"} } ]
    # None of the fields within the publication block are required
    # See https://dataverse.harvard.edu/api/metadatablocks/citation
    # Extract the block that has typename "publication"
    publication_parent_field = citation_fields.find do |field|
      field['typeName'] == 'publication' && field['value'].present?
    end

    # If there is no publication block, we will return an empty array
    return [] if publication_parent_field.blank?

    # 'value' is an array of objects where each object represents a single publication
    # We want to create our DataWorks schema related identifiers object for each
    # of these publications.
    publication_parent_field['value'].filter_map do |publication_field|
      model_related_work(publication_field:)
    end
  end

  # The value property leads to an array where each element represents information about the publication
  def model_related_work(publication_field:)
    id_type = publication_field.dig('publicationIDType', 'value')
    id_number = publication_field.dig('publicationIDNumber', 'value')
    # The possible values for Dataverse publication relationship types controlled vocabulary
    # are allow  within the DataWorks schema:
    # "IsCitedBy","Cites","IsSupplementTo","IsSupplementedBy","IsReferencedBy","References"
    # When no relation type is available, we will keep this field empty
    id_relation = publication_field.dig('publicationRelationType', 'value')

    # We create a mappig if both identifier is available and NOT already in the mapped record
    return unless id_number.present? && !exists_identifier?(id_number, id_type)

    # Normalize id number if it is a doi
    id_number = normalize_dois(id_number, id_type)

    {
      'related_identifier' => id_number,
      'relation_type' => id_relation,
      'related_identifier_type' => map_identifier_type(id_type)
    }.compact_blank
  end

  # Many of the dataverse id types at https://dataverse.harvard.edu/api/metadatablocks/citation
  # publicationIDType are lowercase versions of what is in our schema.
  # For the few exceptions, just return the id type as it is without transformation to uppercase.
  def map_identifier_type(dataverse_id_type)
    return nil if dataverse_id_type.blank?

    return dataverse_id_type if RETAIN_CASE_TYPES.include?(dataverse_id_type)

    dataverse_id_type.upcase
  end

  # Extract related identifiers within the record
  def map_record_related_identifiers
    return [] if @mapped_record['related_identifiers'].blank?

    @mapped_record['related_identifiers']
  end

  # Are the following identifier/identifier type combo already in the mapped record
  def exists_identifier?(id_number, id_type)
    # Normalize the id_number first
    id_number = normalize_dois(id_number, id_type)

    # If there are no such identifiers, return false
    # We are using casecmp to handle any variations in cases in alphanumeric ids
    return false unless @related_identifiers.any? { |ri| ri['related_identifier'].casecmp?(id_number) }

    # If identifier exists, compare id types as well
    matching_id_info = @related_identifiers.find { |ri| ri['related_identifier'].casecmp?(id_number) }
    # Assume DOI if no type at all
    matching_id_type = matching_id_info['related_identifier_type'] || 'DOI'
    # If identifiers are the same, return true if types are also the same
    matching_id_type == map_identifier_type(id_type || 'doi')
  end

  # Strip away any https://doi.org or doi: prefixes
  def normalize_dois(id_number, id_type)
    return id_number unless id_type == 'doi' || id_type.blank?

    id_number.delete_prefix('https://doi.org/').delete_prefix('doi:').strip
  end
end
