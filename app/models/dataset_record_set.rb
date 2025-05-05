# frozen_string_literal: true

# Set of DatasetRecords that were extracted from a provider by a single job
class DatasetRecordSet < ApplicationRecord
  has_many :dataset_record_associations, dependent: :destroy
  has_many :dataset_records, through: :dataset_record_associations

  def self.latest_completed(extractor:, list_args:)
    where(complete: true).where(extractor:).where(list_args:).order(created_at: :desc).first
  end
end
