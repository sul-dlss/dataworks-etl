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

    # @param source [Cocina::Models::DROWithMetadata] the dataset cocina
    # @return [Clients::ListResult]
    def source_to_result(source:)
      Clients::ListResult.new(
        id: source.externalIdentifier,
        modified_token: source.modified,
        source:
      )
    end

    # @param source [Cocina::Models::DROWithMetadata] the dataset cocina
    def doi_from(source:)
      source.identification.doi
    end
  end
end
