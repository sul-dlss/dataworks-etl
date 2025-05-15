# frozen_string_literal: true

module Clients
  # Client for fetching SDR items released to DataWorks
  class Sdr < Base
    def initialize(url: Settings.purl.url, conn: nil)
      super
    end

    # All druids released to DataWorks from SDR, with timestamps
    # @return [Array[Client::ListResult]] datasets
    def list
      purl_fetcher_client.released_to('Dataworks').map do |item|
        Clients::ListResult.new(
          id: item['druid'],
          modified_token: item['updated_at']
        )
      end
    end

    # Fetch the Cocina from PURL for a given dataset by druid
    # @return [Hash] Cocina metadata for the dataset
    def dataset(id:)
      get_json(path: "/#{id}.json")
    end

    private

    def purl_fetcher_client
      @purl_fetcher_client ||= PurlFetcher::Client::Reader.new(
        host: Settings.purl_fetcher.url
      )
    end
  end
end
