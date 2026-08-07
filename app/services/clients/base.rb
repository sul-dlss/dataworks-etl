# frozen_string_literal: true

# Clients for interacting with external APIs
module Clients
  # Error class for client errors
  class Error < StandardError; end

  # Base class for harvesting clients
  class Base
    attr_reader :url, :conn, :username, :password

    # We will caputre specific headers for debugging
    DEBUG_HEADERS = %w[www-authenticate server via date content-type].freeze

    def initialize(url: nil, api_token: nil, username: nil, password: nil, conn: nil)
      @url = url
      @api_token = api_token
      @username = username
      @password = password
      @conn = conn || new_conn
    end

    def get_json(path:, params: {})
      conn.get(path, params.compact).body
    rescue Faraday::Error => e
      raise Error, error_message(e)
    rescue JSON::ParserError => e
      raise Error, "JSON parsing error: #{e.message}"
    end

    private

    attr_reader :api_token

    def error_message(error)
      status = ''
      headers = ''
      body = ''
      if error.response.present?
        status = error.response[:status]
        # We capture the headers if
        headers = error.response[:headers].select { |key, _| DEBUG_HEADERS.include?(key.downcase) }
        # Body may be very long so we are just capturing the first 300 characters
        body = error.response[:body][0, 300] if error.response[:body].present?
      end

      "Connection err: #{error.message} | #{status} | #{headers} | #{body}"
    end

    def new_conn
      Faraday.new({ url: }.compact) do |f|
        f.request :json
        f.request :retry, **retry_options

        if api_token
          f.request :authorization, :Bearer, api_token
        elsif username && password
          f.request :authorization, :basic, username, password
        end

        f.response :json
        f.response :raise_error
      end
    end

    def retry_options
      {
        max: 10,
        interval: 5.0,
        backoff_factor: 2,
        retry_statuses: [429, 500, 502, 503, 504]
      }
    end
  end
end
