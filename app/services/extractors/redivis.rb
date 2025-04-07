# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Redivis
  class Redivis
    def self.call(...)
      new(...).call
    end

    # @param organization [String] the organization to extract datasets for
    def initialize(organization:)
      @organization = organization
    end

    # @return [DatasetRecordSet] the set of dataset records created
    def call
      dataset_record_set = DatasetRecordSet.create!(provider: 'redivis')

      results = client.list
      results.each do |result|
        sleep Settings.extract_sleep
        dataset_record = find_or_create_dataset_record(result:)
        dataset_record_set.dataset_records << dataset_record
      end
      dataset_record_set.update!(complete: true)
      dataset_record_set
    end

    private

    attr_reader :organization

    def client
      @client ||= Clients::Redivis.new(api_token: Rails.application.credentials.redivis_api_token,
                                       organization:)
    end

    def find_or_create_dataset_record(result:)
      dataset_record = DatasetRecord.find_by(provider: 'redivis', dataset_id: result.id)
      return dataset_record if dataset_record

      source = client.dataset(id: result.id)
      DatasetRecord.create!(
        provider: 'redivis',
        dataset_id: result.id,
        modified_token: result.modified_token,
        doi: source['doi'],
        source:
      )
    end
  end
end
