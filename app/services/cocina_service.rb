# frozen_string_literal: true

# Service for fetching Cocina records for SDR items
class CocinaService
  attr_reader :purl_url

  # Initialize the service
  # @param purl_url [String] Base URL for PURL from which to fetch Cocina
  def initialize(purl_url: Settings.purl.url)
    @purl_url = purl_url
  end

  # Fetch the Cocina record from PURL for a given item by druid
  # @return [CocinaDisplay::CocinaRecord] Cocina record for the item
  def cocina_record(druid:)
    CocinaDisplay::CocinaRecord.new(conn.get("/#{druid}.json").body)
  end

  private

  def conn
    @conn ||= Faraday.new(url: purl_url) do |f|
      f.response :json
      f.response :raise_error
    end
  end
end
