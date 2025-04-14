# frozen_string_literal: true

# Job to ETL dataset local metadata
class LocalEtlJob < EtlJob
  include Checkinable

  def perform
    dataset_record_set = Extractors::Local.call
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "LocalEtlJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"

    TransformerLoader.call(dataset_record_set:)
  end
end
