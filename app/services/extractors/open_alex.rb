# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from OpenAlex
  class OpenAlex < Base
    def initialize(institution_id:, extra_dataset_ids: YAML.load_file('config/datasets/open_alex.yml'))
      super(
        client: Clients::OpenAlex.new,
        provider: 'open_alex',
        list_args: { institution_id: },
        extra_dataset_ids: extra_dataset_ids
        )
    end

    private

    def doi_from(source:)
      source['doi']&.delete_prefix('https://doi.org/')
    end

    def source_to_result(source:)
      Clients::ListResult.new(
        id: source['id'],
        modified_token: source['updated_date'].to_s,
        source:
      )
    end
  end
end
