# frozen_string_literal: true

# Clients for interacting with external APIs
module Clients
  # Error class for client errors
  class Error < StandardError; end

  # Base class for harvesting clients
  class Base
    attr_reader :conn

    def initialize(conn: nil)
      @conn = conn || new_conn
    end

    def get_json(path:, params: {})
      response = conn.get(path, params.compact)

      raise Clients::Error, "Error: #{response.status}" unless response.success?

      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise Error, "Connection err: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "JSON parsing error: #{e.message}"
    end

    private

    def new_conn
      raise NotImplementedError
    end

    def retry_options
      {
        max: 10,
        interval: 5.0,
        backoff_factor: 2,
        retry_statuses: [429, 502]
      }
    end
  end
end
