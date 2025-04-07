# frozen_string_literal: true

# Job to ETL dataset metadata from Redivis
class RedivisEtlJob < EtlJob
  def perform(organization:)
    dataset_record_set = Extractors::Redivis.call(organization:)
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "RedivisEtlJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"

    TransformerLoader.call(dataset_record_set:)
  end
end
