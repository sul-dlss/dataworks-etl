# frozen_string_literal: true

# Set of DatasetSource records that were extracted from a provider by a single job
class DatasetSourceSet < ApplicationRecord
  has_many :dataset_source_associations, dependent: :destroy
  has_many :dataset_sources, through: :dataset_source_associations
end
