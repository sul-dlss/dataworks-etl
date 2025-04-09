# frozen_string_literal: true

module Clients
  # Client for interacting with the Redivis API
  class Redivis < Clients::Base
    def initialize(api_token:, organization:, conn: nil)
      super(conn:)
      @api_token = api_token
      @organization = organization
    end

    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(max_results: 100)
      results, page_token = list_page(max_results: max_results)
      while page_token
        next_results, page_token = list_page(max_results: max_results, page_token: page_token)
        results.concat(next_results)
      end
      results
    end

    def dataset(id:)
      get_json(path: "/api/v1/datasets/#{id}")
    end

    private

    attr_reader :api_token, :organization

    def new_conn
      Faraday.new(
        url: 'https://redivis.com',
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{api_token}"
        }
      )
    end

    def list_page(max_results:, page_token: nil)
      response_json = get_json(path: "/api/v1/organizations/#{organization}/datasets",
                               params: { maxResults: max_results, pageToken: page_token })
      results = response_json['results'].map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['qualifiedReference'],
          modified_token: dataset_json['updatedAt'].to_s
        )
      end
      [results, response_json['nextPageToken']]
    end
  end
end
