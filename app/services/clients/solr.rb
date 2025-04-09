# frozen_string_literal: true

module Clients
  # Client for harvesting from a Solr index (e.g. Searchworks)
  class Solr < Clients::Base
    def initialize(conn: nil)
      super
      @solr = RSolr.connect conn
    end

    private

    def new_conn
      Faraday.new(
        url: 'https://sul-solr-prod-a.stanford.edu',
        headers: {
          'Accept' => 'application/json'
        }
      )
    end
  end
end
