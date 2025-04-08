# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Datacite
  class Datacite < ClientBase
    def initialize(affiliation: 'Stanford University')
      super(client: Clients::Datacite.new, provider: 'datacite', list_args: { affiliation: })
    end

    private

    def doi_from(source:)
      source.dig('data', 'id')
    end
  end
end
