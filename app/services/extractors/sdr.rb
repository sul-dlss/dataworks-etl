# frozen_string_literal: true

module Extractors
  # Extractor for SDR content that produces Cocina source records
  class Sdr < Base
    def initialize(
      client: Clients::Sdr.new,
      provider: 'sdr',
      extra_dataset_ids: YAML.load_file('config/datasets/sdr.yml')
    )
      super
    end

    private

    # @param source [Hash] the dataset cocina
    # @return [Clients::ListResult]
    def source_to_result(source:)
      Clients::ListResult.new(
        id: source['externalIdentifier'],
        modified_token: source['modified'],
        source: source
      )
    end

    # @param source [Hash] the dataset cocina
    # Delegate to the mapper since this can be in multiple places
    def doi_from(source:)
      DataworksMappers::Sdr.doi(source:)
    end
  end
end
