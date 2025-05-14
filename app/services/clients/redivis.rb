# frozen_string_literal: true

module Clients
  # Client for interacting with the Redivis API
  class Redivis < Clients::Base
    def initialize(api_token:, url: 'https://redivis.com', conn: nil)
      super(url: url, api_token: api_token, conn: conn)
    end

    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(organization:, max_results: 100)
      results, page_token = list_page(organization:, max_results: max_results)
      while page_token
        next_results, page_token = list_page(organization:, max_results: max_results, page_token: page_token)
        results.concat(next_results)
      end
      results
    end

    def dataset(id:)
      # This creates a synthetic source record that includes additional table and variable metadata.
      get_json(path: "/api/v1/datasets/#{id}").tap do |dataset|
        add_tables(dataset:) if dataset['tableCount'].positive? && dataset['publicAccessLevel'] == 'data'
      end
    end

    private

    def list_page(organization:, max_results:, page_token: nil)
      response_json = get_json(path: "/api/v1/organizations/#{organization}/datasets",
                               params: { maxResults: max_results, pageToken: page_token })
      results = response_json['results'].map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['qualifiedReference'],
          modified_token: dataset_json['updatedAt'].to_s,
          source: nil
        )
      end
      [results, response_json['nextPageToken']]
    end

    def add_tables(dataset:)
      # Requesting 1000 tables to avoid having to paginate. (As of 05-2025, the max tables is 102.)
      response_json = get_json(path: "/api/v1/datasets/#{dataset['qualifiedReference']}/tables",
                               params: { maxResults: 1000 })
      tables = response_json['results']
      tables.each do |table|
        add_variables(table:) if table['variableCount'].positive?
      end

      dataset['tables'] = tables
    end

    def add_variables(table:)
      # Requesting 10,000 variables to avoid having to paginate.
      response_json = get_json(path: "/api/v1/tables/#{table['qualifiedReference']}/variables",
                               params: { maxResults: 10_000 })
      variables = response_json['results']
      table['variables'] = variables
    end
  end
end
