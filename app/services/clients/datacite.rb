# frozen_string_literal: true

module Clients
  # Client for interacting with the Datacite API
  class Datacite < Clients::Base
    def initialize(url: 'https://api.datacite.org', conn: nil)
      super
    end

    # @param affiliation [String] the affiliation to search for (optional)
    # @param page_size [Integer] the number of results to return per page (optional, default: 1000)
    # @param client_id [String] the client ID to use for the request (optional)
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(affiliation: nil, page_size: 1000, client_id: nil)
      raise Clients::Error, 'client_id cannot be used with affiliation' if affiliation && client_id
      raise Clients::Error, 'affiliation or client_id required' unless affiliation || client_id

      @affiliation = affiliation
      @client_id = client_id

      results, cursor = list_page(page_size:)
      while cursor
        next_results, cursor = list_page(page_size:, cursor:)
        results.concat(next_results)
      end
      results
    end

    attr_reader :affiliation, :client_id

    # @param id [String] the DOI of the dataset
    def dataset(id:)
      get_json(path: "/dois/#{id}", params: { affiliation: true, publisher: true })
    end

    private

    def list_page(page_size:, cursor: 1)
      response_json = get_json(path: '/dois',
                               params: params(page_size:, cursor:))
      results = response_json['data'].map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['id'],
          modified_token: dataset_json.dig('attributes', 'updated'),
          source: nil
        )
      end
      cursor = cursor(link: response_json.dig('links', 'next'))
      [results, cursor]
    end

    def params(page_size:, cursor:)
      {
        'page[size]': page_size,
        'page[cursor]': cursor,
        'resource-type-id': 'dataset'
      }.tap do |params|
        if client_id
          params['client-id'] = client_id
        else
          params['query'] = "creators.affiliation.name:\"#{affiliation}\""
        end
      end
    end

    def cursor(link:)
      return unless link

      uri = URI.parse(link)
      params = CGI.unescape(uri.query).split('&').to_h { |param| param.split('=') }
      params['page[cursor]']
    end
  end
end
