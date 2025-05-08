# frozen_string_literal: true

module Clients
  # Client for harvesting from a Solr index (e.g. Searchworks)
  class Solr < Clients::Base
    def initialize(url: Settings.searchworks.solr_url, conn: nil)
      super
      @solr = RSolr.connect @conn, url:
    end

    # Enumerable of solr documents matching a solr query
    # Note that since the format of solr documents can vary this does NOT return a ListResult.
    # @param params [Hash] solr query params
    # @param page_size [Integer] number of results per page
    # @yield [Hash] dataset
    # @return [integer] total number of results
    def list(params:, page_size: 1000, &)
      return to_enum(:list, params:, page_size:) unless block_given?

      # Get the first page and be done if there aren't any more
      response = list_page(params:, page_size:, page: 1)
      total = response['numFound']
      response['docs'].each(&)
      return total unless total > page_size

      # Get the rest of the pages
      (2..(total.to_f / page_size).ceil).each do |page|
        list_page(params:, page_size:, page:)['docs'].each(&)
      end
      total
    end

    # Fetch a single dataset by solr id
    # @param id [String] solr id (in Searchworks, folio hrid or druid)
    # @return [Hash] dataset
    def dataset(id:, params: {})
      @solr.get('select', params: params.merge(q: "id:#{id}")).dig('response', 'docs', 0)
    end

    private

    # FlatParamsEncoder is required to send params like 'fl' multiple times; it
    # is not the default in Faraday but is the default in RSolr. RSolr also
    # wants to parse JSON on its own so we can't use Faraday's JSON middleware.
    def new_conn(url:, api_token: nil)
      base_conn = super
      base_conn.options.params_encoder = Faraday::FlatParamsEncoder
      base_conn.builder.delete Faraday::Response::Json
      base_conn
    end

    def list_page(params:, page_size:, page:)
      @solr.paginate(page, page_size, 'select', params:)['response']
    end
  end
end
