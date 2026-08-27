# frozen_string_literal: true

module Clients
  # Client for interacting with the OpenAlex API
  class OpenAlex < Clients::Base
    def initialize(url: 'https://api.openalex.org', api_token: nil, conn: nil)
      super
    end

    # @param institution_id [String] the OpenAlexID to retrieve datasets for
    # @param page_size [Integer] the number of results to return per page (optional, default/max: 200)
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(institution_id:, type: 'dataset', page_size: 200)
      @institution_id = institution_id
      @type = type
      @page_size = page_size

      results, cursor = list_page
      while cursor
        next_results, cursor = list_page(cursor:)
        results.concat(next_results)
      end
      results
    end

    # This is for related works filter query
    # @param relationship [String] the relationship we wish to filter by, cites or cited_by
    # @param doi [String] the DOI of the work we wish to query for
    # @param page_size [Integer] the number of results to return per page (optional, default/max: 200)
    # @return list of results combined from multiple calls if required
    # @raise [Clients::Error] if the request fails
    def query_relationship(relationship:, id:, page_size: 200)
      @page_size = page_size
      results, cursor = query_relationship_page(relationship:, id:)
      while cursor
        next_results, cursor = query_relationship_page(cursor:, relationship:, id:)
        results.concat(next_results)
      end
      results
    end

    attr_reader :institution_id, :type, :page_size

    # @param id [String] the Identifier of the dataset
    def dataset(id:)
      get_json(path: "/works/#{id.delete_prefix('https://openalex.org/')}")
    end

    # @param doi [String] the DOI of the dataset
    def dataset_doi(doi:)
      get_json(path: "/works/https://doi.org/#{doi}")
    end

    # Pass API key as a query parameter if provided
    def get_json(path:, params: {})
      params.merge!({ api_key: api_token }) if api_token
      super
    end

    private

    def list_page(cursor: '*')
      response_json = get_json(path: '/works',
                               params: params(cursor:))
      results = response_json['results'].map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['id'],
          modified_token: dataset_json['updated_date'].to_s,
          source: dataset_json
        )
      end
      cursor = response_json.dig('meta', 'next_cursor')
      [results, cursor]
    end

    # Run query and use the cursor-based method to select a particular page
    def query_relationship_page(relationship:, id:, cursor: '*')
      response_json = get_json(path: '/works',
                               params: query_relationship_params(cursor:, relationship:, id:))
      results = response_json['results']
      cursor = response_json.dig('meta', 'next_cursor')
      [results, cursor]
    end

    def query_relationship_params(cursor:, relationship:, id:)
      {
        cursor: cursor,
        filter: "#{relationship}:#{id},type:!dataset|database|software",
        'per-page': page_size,
        select: 'id,doi,ids'
      }
    end

    def params(cursor:)
      {
        filter: "institutions.id:#{institution_id},type:#{type}",
        'per-page': page_size,
        cursor: cursor
      }
    end
  end
end
