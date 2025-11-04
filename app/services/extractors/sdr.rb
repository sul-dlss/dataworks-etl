# frozen_string_literal: true

module Extractors
  # Extractor for SDR content that produces Cocina source records
  class Sdr < Base
    def initialize(
      client: CocinaService.new(purl_url: 'https://purl.stanford.edu'),
      provider: 'sdr',
      extra_dataset_ids: YAML.load_file('config/datasets/sdr.yml')
    )
      super
    end

    private

    # For SDR, we use a single persistent set rather than creating a new one
    # each harvest. This supports both incremental and on-demand harvesting
    def create_dataset_record_set
      DatasetRecordSet.find_or_create_by!(provider: provider, complete: true)
    end

    # Only index what was specified in extra_dataset_ids; everything else
    # comes in through the SdrConsumer
    def results
      return [] if extra_dataset_ids.blank?

      extra_dataset_ids.map do |druid|
        source = client.cocina_record(druid:)
        source_to_result(source:)
      end
    end

    # @param source [Hash] the dataset cocina
    # @return [Clients::ListResult]
    def source_to_result(source:)
      Clients::ListResult.new(
        id: source.druid,
        modified_token: source.modified_time,
        source: source.cocina_doc
      )
    end

    # @param source [Hash] the dataset cocina
    # Delegate to the mapper since this can be in multiple places
    def doi_from(source:)
      DataworksMappers::Sdr.doi(source:)
    end
  end
end
