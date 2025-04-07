# frozen_string_literal: true

# Join between DatasetRecord and DatasetRecordSet
class DatasetRecordAssociation < ApplicationRecord
  belongs_to :dataset_record
  belongs_to :dataset_record_set
end
