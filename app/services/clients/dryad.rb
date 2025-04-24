# frozen_string_literal: true

module Clients
  # Client for interacting with the Dryad API
  class Dryad < Clients::Base
    def initialize(url: 'https://datadryad.org', conn: nil)
      super
    end

    # @param affiliation [String] the ROR ID of the organization
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(affiliation:, per_page: 100, page_sleep: Settings.dryad_extract_sleep)
      page = 1
      [].tap do |results|
        while page
          next_results, page = list_page(affiliation:, per_page:, page:)
          results.concat(next_results)
          sleep page_sleep
        end
      end
    end

    # @param id [String] the DOI of the dataset
    def dataset(id:)
      get_json(path: "/api/v2/datasets/#{CGI.escape(id)}")
    end

    private

    def list_page(affiliation:, per_page:, page:)
      response_json = get_json(path: '/api/v2/search',
                               params: { affiliation:, per_page:, page: })

      results = response_json.dig('_embedded', 'stash:datasets').map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['identifier'],
          modified_token: dataset_json['versionNumber'].to_s,
          source: nil
        )
      end
      next_page = response_json.dig('_links', 'next', 'href').present? ? page + 1 : nil
      [results, next_page]
    end
  end
end
