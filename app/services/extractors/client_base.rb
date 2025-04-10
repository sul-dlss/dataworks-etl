# frozen_string_literal: true

module Extractors
  # Base class for extractors that use a client with list and dataset methods
  class ClientBase
    def self.call(...)
      new(...).call
    end

    def initialize(client:, provider:, list_args: {}, extract_sleep: Settings.extract_sleep)
      @client = client
      @provider = provider
      @list_args = list_args
      @extract_sleep = extract_sleep
    end

    # @return [DatasetRecordSet] the set of dataset records created
    def call
      dataset_record_set = DatasetRecordSet.create!(provider:)

      results = client.list(**list_args)
      results.each do |result|
        dataset_record = find_or_create_dataset_record(result:)
        dataset_record_set.dataset_records << dataset_record
      end
      dataset_record_set.update!(complete: true)
      dataset_record_set
    end

    private

    attr_reader :client, :provider, :list_args, :extract_sleep

    def find_or_create_dataset_record(result:)
      DatasetRecord.find_by(provider:, dataset_id: result.id) || create_dataset_record(result:)
    end

    def create_dataset_record(result:)
      # If we already have the source use it, otherwise fetch it by ID
      source = result.source || client.dataset(id: result.id)
      sleep extract_sleep
      DatasetRecord.create!(
        provider:,
        dataset_id: result.id,
        modified_token: result.modified_token,
        doi: doi_from(source:),
        source:
      )
    end

    # @param source [Hash] the source metadata for the dataset
    # @return [String] the DOI for the dataset
    def doi_from(source:)
      raise NotImplementedError
    end
  end
end
