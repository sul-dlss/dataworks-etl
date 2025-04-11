# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Zenodo
  class Zenodo < Base
    def initialize(extra_dataset_ids: YAML.load_file('config/datasets/zenodo.yml'))
      super(client: Clients::Zenodo.new(api_token: Settings.zenodo.api_token),
            provider: 'zenodo',
            list_args: { affiliation: 'Stanford University' },
            extra_dataset_ids:
            )
    end

    private

    def doi_from(source:)
      source['doi']
    end

    def source_to_result(source:)
      Clients::ListResult.new(
        id: source['id'].to_s,
        modified_token: source['revision'].to_s,
        source:
      )
    end
  end
end
