# frozen_string_literal: true

# Source metadata for a dataset
class DatasetSource < ApplicationRecord
  has_many :dataset_source_associations, dependent: :destroy
  has_many :dataset_source_sets, through: :dataset_source_associations

  before_save ->(dataset_source) { dataset_source.source_md5 = Digest::MD5.hexdigest(dataset_source.source.to_json) }
end
