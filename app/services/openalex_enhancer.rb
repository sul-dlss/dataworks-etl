# frozen_string_literal: true

# Add specific metadata from OpenAlex for a given dataset
class OpenalexEnhancer
  def initialize(mapped_record:, doi:)
    @mapped_record = mapped_record
    @doi = doi
    @mapped_record_dois = map_record_related_dois
    @client = Clients::OpenAlex.new(api_token: Settings.open_alex.api_token)
    @openalex_record = @client.dataset_doi(doi: @doi) if doi.present?
  rescue Clients::Error => e
    # We do not want Honeybadger notifications b/c OpenAlex provides a 404
    # for any dataset that does not exist
    Rails.logger.error { "OpenAlex record retrieval error for #{@doi}, #{e}" }
  end

  def add_metadata
    return @mapped_record if @doi.blank? || @openalex_record.blank?

    @mapped_record = add_publications_metadata
    @mapped_record = add_access
    @mapped_record
  rescue Clients::Error => e
    # Log any error that might occur with the client
    error_msg = "OpenAlex metadata enhancement client error, #{e}"
    Rails.logger.error { error_msg }
    Honeybadger.notify(error_msg)
  end

  # Add publication related information
  def add_publications_metadata
    @id = @openalex_record['id']
    # Publications this work references. The filter query uses order: works cited_by this work
    cites = related_publications(relationship: 'cited_by', field: 'referenced_works_count')
    # Publications that cite this work, or those this work is cited by
    # The filter query uses the order: works that cite this work
    cited_by = related_publications(relationship: 'cites', field: 'cited_by_count')
    all_publications = cites.concat(cited_by)

    if all_publications.size.positive?
      @mapped_record['related_identifiers'] = [] if @mapped_record['related_identifiers'].blank?

      @mapped_record['related_identifiers'].concat(all_publications)
    end

    @mapped_record
  end

  # This returns related publications but leaves out any DOIs that are already present in
  # the related identifiers list in the metadata record
  def related_publications(relationship:, field:)
    # If the count field for this relationship is 0, we will not query for this relationship
    return [] unless @openalex_record[field].to_i.positive?

    # Query open alex for referenced works that not datasets, databases, software
    related_works = @client.query_relationship(relationship:, id: @id)
    related_works.filter_map do |related_work|
      unless related_work['doi'].present? && @mapped_record_dois.include?(related_work['doi'].delete_prefix('https://doi.org/'))
        model_related_work(relationship:,
                           related_work:)
      end
    end
  end

  def model_related_work(relationship:, related_work:)
    {
      'related_identifier' => related_work['id'].delete_prefix('https://openalex.org/'),
      'relation_type' => relationship_label(relationship:),
      'related_identifier_type' => 'OpenAlex'
    }
  end

  # The filter query is in the opposite direction of outgoing relationships from the work
  # i.e. filter cites:W1 means works that cite W1, which when looking at the page for W1
  # would display as Is Cited By
  def relationship_label(relationship:)
    relationship == 'cites' ? 'IsCitedBy' : 'Cites'
  end

  def map_record_related_dois
    return [] if @mapped_record['related_identifiers'].blank?

    @mapped_record['related_identifiers'].filter_map do |info|
      info['related_identifier'] if info['related_identifier_type'].blank? || info['related_identifier_type'] == 'DOI'
    end
  end

  # Add access information into the rights list
  def add_access
    oa_status = @openalex_record['open_access']['is_oa']
    oa_rights = oa_status == true ? 'Open access' : 'Not open access'
    @mapped_record['rights_list'] = [] if @mapped_record['rights_list'].blank?
    @mapped_record['rights_list'] << { 'rights' => oa_rights }
    @mapped_record
  end
end
