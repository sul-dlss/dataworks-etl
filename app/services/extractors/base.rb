# frozen_string_literal: true

module Extractors
  # Base class for extractors that use a client with list and dataset methods
  class Base
    def self.call(...)
      new(...).call
    end

    def initialize(client:, provider:, list_args: {}, extract_sleep: Settings.extract_sleep, extra_dataset_ids: [])
      @client = client
      @provider = provider
      @list_args = list_args
      @extract_sleep = extract_sleep
      @extra_dataset_ids = extra_dataset_ids
    end

    # @return [DatasetRecordSet] the set of dataset records created
    def call
      dataset_record_set = DatasetRecordSet.create!(provider:, extractor: self.class.name, list_args: list_args.to_json)

      results.each do |result|
        dataset_record = find_or_create_dataset_record(result:)
        dataset_record_set.dataset_records << dataset_record
      end
      dataset_record_set.update!(complete: true)
      dataset_record_set
    end

    private

    attr_reader :client, :provider, :list_args, :extract_sleep, :extra_dataset_ids

    def results
      (extra_dataset_results + client.list(**list_args)).uniq(&:id)
    end

    def extra_dataset_results
      return [] if extra_dataset_ids.blank?

      extra_dataset_ids.map do |id|
        source = client.dataset(id:)
        source_to_result(source:)
      end
    end

    # @param source [Hash|Cocina::Models::DROWithMetadata] the source from the client
    # @return [Client::ListResult] the ListResult generated from the source
    def source_to_result(source:)
      raise NotImplementedError
    end

    def find_or_create_dataset_record(result:)
      DatasetRecord.find_by(provider:, dataset_id: result.id, modified_token: result.modified_token) ||
        create_dataset_record(result:)
    end

    def create_dataset_record(result:)
      # If we already have the source use it, otherwise fetch it by ID
      source = result.source || retrieve_source(id: result.id)
      DatasetRecord.create!(
        provider:,
        dataset_id: result.id,
        modified_token: result.modified_token,
        doi: doi_from(source:),
        source:
      )
    end

    def retrieve_source(id:)
      sleep extract_sleep
      client.dataset(id:)
    end

    # @param source [Hash] the source metadata for the dataset
    # @return [String] the DOI for the dataset
    def doi_from(source:)
      raise NotImplementedError
    end
  end
end
