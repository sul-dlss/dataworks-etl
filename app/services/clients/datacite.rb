# frozen_string_literal: true

module Clients
  # Client for interacting with the Datacite API
  class Datacite < Clients::Base
    def initialize(url: 'https://api.datacite.org', conn: nil)
      super
    end

    # @param affiliation [String] the affiliation to search for (optional)
    # @param client_id [String] the client ID to use for the request (optional)
    # @param provider_id [String] the provider ID to use for the request (optional)
    # @param page_size [Integer] the number of results to return per page (optional, default: 1000)
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(affiliation: nil, client_id: nil, provider_id: nil, page_size: 1000)
      @query = if client_id
                 ClientIdQuery.new(client_id:)
               elsif affiliation
                 AffiliationQuery.new(affiliation:)
               elsif provider_id
                 ProviderIdQuery.new(provider_id:)
               else
                 raise ArgumentError, 'at least one query parameter is required'
               end

      results, cursor = list_page(page_size:)
      while cursor
        next_results, cursor = list_page(page_size:, cursor:)
        results.concat(next_results)
      end
      results
    end

    attr_reader :query

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
      }.merge(query.to_params)
    end

    def cursor(link:)
      return unless link

      uri = URI.parse(link)
      params = CGI.unescape(uri.query).split('&').to_h { |param| param.split('=') }
      params['page[cursor]']
    end

    # Query by client ID
    class ClientIdQuery
      def initialize(client_id:)
        @client_id = client_id
      end

      def to_params
        { 'client-id': @client_id }
      end
    end

    # Query by affiliation
    class AffiliationQuery
      def initialize(affiliation:)
        @affiliation = affiliation
      end

      def to_params
        { query: "creators.affiliation.name:\"#{@affiliation}\"" }
      end
    end

    # Query by provider ID
    class ProviderIdQuery
      def initialize(provider_id:)
        @provider_id = provider_id
      end

      def to_params
        { 'provider-id': @provider_id }
      end
    end
  end
end
