# frozen_string_literal: true

# Map from Dataworks metadata to Solr metadata
class SolrMapper
  def self.call(...)
    new(...).call
  end

  # @param metadata [Hash] the Dataworks metadata
  def initialize(metadata:, dataset_record_id:, dataset_record_set_id:)
    @metadata = metadata.with_indifferent_access
    @dataset_record_id = dataset_record_id
    @dataset_record_set_id = dataset_record_set_id
  end

  # @return [Hash] the Solr document
  def call
    {
      id: dataset_record_id,
      dataset_record_set_id: dataset_record_set_id,
      title: metadata.dig(:titles, 0, :title)
    }
  end

  private

  attr_reader :metadata, :dataset_record_id, :dataset_record_set_id
end
