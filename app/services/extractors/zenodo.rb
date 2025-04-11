# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Zenodo
  class Zenodo < Base
    def initialize
      super(client: Clients::Zenodo.new(api_token: Settings.zenodo.api_token),
            provider: 'zenodo', list_args: { affiliation: 'Stanford University' })
    end

    private

    def doi_from(source:)
      source['doi']
    end
  end
end
