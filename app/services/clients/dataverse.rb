# frozen_string_literal: true

module Clients
  # Client for interacting with the Harvard Dataverse API and for retrieving
  # metadata for individual dataset
  class Dataverse < Clients::Base
    def initialize(dataverse_token:, url: 'https://dataverse.harvard.edu', conn: nil)
      # Passing in api_token into constructor will pass in Bearer heading
      # which we do not want in additon to the X-Dataverse-key header
      @dataverse_token = dataverse_token
      super(url: url, conn: conn)
    end

    # Dataverse prefers we pass in the api token in the X-Dataverse-key header
    def new_conn
      Rails.logger.info('Dataverse token does not exist') if @dataverse_token.blank?
      base_conn = super
      base_conn.headers['X-Dataverse-key'] = @dataverse_token
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
