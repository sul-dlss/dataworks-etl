# frozen_string_literal: true

module Extractors
  # Service for extracting OpenNeuro datasets from Datacite
  class OpenNeuro < Base
    def initialize(affiliation: 'Stanford University',
                   client_id: 'sul.openneuro')
      super(
        client: Clients::Datacite.new,
        provider: 'open_neuro',
        list_args: { affiliation:, client_id: }
        )
    end

    private

    def doi_from(source:)
      source.dig('data', 'id')
    end

    def source_to_result(source:)
      Clients::ListResult.new(
        id: source.dig('data', 'id'),
        modified_token: source.dig('data', 'attributes', 'version'),
        source:
      )
    end
  end
end
