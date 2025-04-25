# frozen_string_literal: true

module Clients
  # Client for fetching SDR items released to DataWorks
  class Sdr < Base
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

    # Fetch the Cocina from SDR for a given dataset by druid
    # @return [Cocina::Models::DROWithMetadata] Cocina model for the dataset
    def dataset(id:)
      sdr_client.object("druid:#{id}").find
    end

    private

    def purl_fetcher_client
      @purl_fetcher_client ||= PurlFetcher::Client::Reader.new(
        host: Settings.purl_fetcher.url
      )
    end

    def sdr_client
      @sdr_client ||= Dor::Services::Client.configure(
        url: Settings.dor_services.url,
        token: Settings.dor_services.token,
        enable_get_retries: true
      )
    end
  end
end
