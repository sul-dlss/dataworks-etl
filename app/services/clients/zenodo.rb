# frozen_string_literal: true

class Clients
  # Client for interacting with the Zenodo API
  class Zenodo
    def initialize(api_token:)
      @api_token = api_token
    end

    # @param affiliation [String] name of the organization
    # @return [Array<Clients::ListResult>] array of ListResults for the datasets
    # @raise [Clients::Error] if the request fails
    def list(affiliation:, page_size: 250)
      page = 1
      [].tap do |results|
        while page
          next_results, page = list_page(affiliation:, page_size:, page:)
          results.concat(next_results)
        end
      end
    end

    def dataset(id:)
      Clients.get_json(conn: conn, path: "/api/records/#{id}")
    end

    private

    attr_reader :api_token

    def conn
      @conn ||= Faraday.new(
        url: 'https://zenodo.org',
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{api_token}"
        }
      )
    end

    def list_page(affiliation:, page_size:, page:)
      response_json = Clients.get_json(conn: conn, path: '/api/records',
                                       params: params(affiliation:, page_size:, page:))
      results = response_json.dig('hits', 'hits').map do |dataset_json|
        Clients::ListResult.new(
          id: dataset_json['id'].to_s,
          modified_token: dataset_json['revision'].to_s
        )
      end
      next_page = response_json.dig('links', 'next').present? ? page + 1 : nil
      [results, next_page]
    end

    def params(affiliation:, page_size:, page:)
      {
        size: page_size,
        page:,
        q: "creators.affiliation:\"#{affiliation}\"",
        type: 'dataset'
      }
    end
  end
end
