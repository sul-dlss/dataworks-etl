# frozen_string_literal: true

module Clients
  # Client for interacting with the OpenAlex API
  class OpenAlex < Clients::Base
    def initialize(url: 'https://api.openalex.org', conn: nil)
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

    attr_reader :institution_id, :type, :page_size

    # @param id [String] the Identifier of the dataset
    def dataset(id:)
      get_json(path: "/works/#{id.delete_prefix('https://openalex.org/')}")
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

    def params(cursor:)
      {
        filter: "institutions.id:#{institution_id},type:#{type}",
        'per-page': page_size,
        cursor: cursor
      }
    end
  end
end
