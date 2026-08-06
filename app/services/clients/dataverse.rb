# frozen_string_literal: true

module Clients
  # Client for interacting with the Harvard Dataverse API and for retrieving
  # metadata for individual dataset
  class Dataverse < Clients::Base
    def initialize(api_token:, url: 'https://dataverse.harvard.edu', conn: nil)
      # We will not pass this into the base initializer b/c we do not use
      # the bearer token pattern
      @api_token = api_token
      super(url: url, conn: conn)
    end

    # Dataverse prefers we pass in the api token in the X-Dataverse-key header
    def new_conn
      base_conn = super
      base_conn.headers['X-Dataverse-key'] = @api_token
      Rails.logger.info("API token exists? #{@api_token.present?}")
      base_conn
    end

    # @param doi [String] the DOI of the dataset
    def dataset_doi(doi:)
      # params ?persistentId=doi:#{doi}
      get_json(path: '/api/datasets/:persistentId/',
               params: { persistentId: "doi:#{doi}" })
    end
  end
end
