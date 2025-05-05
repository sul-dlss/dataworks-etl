# frozen_string_literal: true

# Job to extract dataset metadata from Zenodo
class ZenodoExtractJob < ExtractJob
  include Checkinable

  def perform
    dataset_record_set = Extractors::Zenodo.call
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "ZenodoExtractJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"
  end
end
