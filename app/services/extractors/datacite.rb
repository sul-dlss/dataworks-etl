# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Datacite
  class Datacite < Base
    def initialize(affiliation: 'Stanford University',
                   extra_dataset_ids: YAML.load_file('config/datasets/datacite.yml'))
      super(
        client: Clients::Datacite.new,
        provider: 'datacite',
        list_args: { affiliation: },
        extra_dataset_ids: extra_dataset_ids
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
