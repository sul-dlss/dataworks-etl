# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Dryad
  class Dryad < Base
    def initialize(affiliation: 'https://ror.org/00f54p054',
                   extra_dataset_ids: YAML.load_file('config/datasets/dryad.yml'))
      super(
        client: Clients::Dryad.new,
        provider: 'dryad',
        list_args: { affiliation: },
        extract_sleep: Settings.dryad_extract_sleep,
        extra_dataset_ids:
        )
    end

    private

    def doi_from(source:)
      source['identifier'].delete_prefix('doi:')
    end

    def source_to_result(source:)
      Clients::ListResult.new(
        id: source['identifier'],
        modified_token: source['versionNumber'],
        source:
      )
    end
  end
end
