# frozen_string_literal: true

# Source metadata for a dataset
class DatasetRecord < ApplicationRecord
  has_many :dataset_record_associations, dependent: :destroy
  has_many :dataset_record_sets, through: :dataset_record_associations

  before_save ->(dataset_record) { dataset_record.source_md5 = Digest::MD5.hexdigest(dataset_record.source.to_json) }

  # @return [String] unique identifier for the dataset (independent of the provider)
  def external_dataset_id
    doi || [provider, dataset_id].join('-')
  end
end
