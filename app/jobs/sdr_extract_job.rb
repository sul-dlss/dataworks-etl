# frozen_string_literal: true

# Job to extract dataset metadata from SDR
class SdrExtractJob < ExtractJob
  include Checkinable

  def perform
    dataset_record_set = Extractors::Sdr.call

    Rails.logger.info "SdrExtractJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{@job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"
  end
end
