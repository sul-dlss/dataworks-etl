# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Redivis
  class Redivis < Base
    # @param organization [String] the organization to extract datasets for
    def initialize(organization:)
      super(client: Clients::Redivis.new(api_token: Settings.redivis.api_token, organization:),
            provider: 'redivis')
    end

    private

    def doi_from(source:)
      source['doi']
    end
  end
end
