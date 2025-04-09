# frozen_string_literal: true

module Clients
  # Client for interacting with the Datacite API
  class Datacite < Clients::Base
    # @param affiliation [String] the affiliation to search for
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(affiliation:, page_size: 1000)
      results, cursor = list_page(affiliation:, page_size:)
      while cursor
        next_results, cursor = list_page(affiliation:, page_size:, cursor:)
        results.concat(next_results)
      end
      results
    end

    # @param id [String] the DOI of the dataset
    def dataset(id:)
      get_json(path: "/dois/#{id}")
    end

    private

    def new_conn
      Faraday.new(
        url: 'https://api.datacite.org',
        headers: {
          'Accept' => 'application/json'
        }
      )
    end

    def list_page(affiliation:, page_size:, cursor: 1)
      response_json = get_json(path: '/dois',
                               params: params(affiliation:, page_size:, cursor:))
      results = response_json['data'].map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['id'],
          modified_token: dataset_json.dig('attributes', 'updated')
        )
      end
      cursor = cursor(link: response_json.dig('links', 'next'))
      [results, cursor]
    end

    def params(affiliation:, page_size:, cursor:)
      {
        'page[size]': page_size,
        'page[cursor]': cursor,
        'resource-type-id': 'dataset',
        query: "creators.affiliation.name:\"#{affiliation}\""
      }
    end

    def cursor(link:)
      return unless link

      uri = URI.parse(link)
      params = CGI.unescape(uri.query).split('&').to_h { |param| param.split('=') }
      params['page[cursor]']
    end
  end
end
