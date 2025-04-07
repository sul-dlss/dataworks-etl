# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Redivis
  class Redivis
    def self.call(...)
      new(...).call
    end

    def initialize(organization:)
      @organization = organization
    end

    def call
      dataset_source_set = DatasetSourceSet.create!(provider: 'redivis')

      results = client.list
      results.each do |result|
        sleep Settings.extract_sleep
        dataset_source = find_or_create_dataset_source(result:)
        dataset_source_set.dataset_sources << dataset_source
      end
      dataset_source_set.update!(complete: true)
    end

    private

    attr_reader :organization

    def client
      @client ||= Clients::Redivis.new(api_token: Rails.application.credentials.redivis_api_token,
                                       organization:)
    end

    def find_or_create_dataset_source(result:)
      dataset_source = DatasetSource.find_by(provider: 'redivis', dataset_id: result.id)
      return dataset_source if dataset_source

      source = client.dataset(id: result.id)
      DatasetSource.create!(
        provider: 'redivis',
        dataset_id: result.id,
        modified_token: result.modified_token,
        doi: source['doi'],
        source:
      )
    end
  end
end
