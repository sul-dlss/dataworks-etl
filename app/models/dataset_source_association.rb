# frozen_string_literal: true

# Join between DatasetSource and DatasetSourceSet
class DatasetSourceAssociation < ApplicationRecord
  belongs_to :dataset_source
  belongs_to :dataset_source_set
end
