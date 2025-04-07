# frozen_string_literal: true

# Clients for interacting with external APIs
class Clients
  ListResult = Struct.new('ListResult', :id, :modified_token, keyword_init: true)

  class Error < StandardError; end

  def self.get_json(conn:, path:, params: {})
    response = conn.get(path, params.compact)

    raise Clients::Error, "Error: #{response.status}" unless response.success?

    JSON.parse(response.body)
  rescue Faraday::Error => e
    raise Error, "Connection errr: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "JSON parsing error: #{e.message}"
  end
end
