# frozen_string_literal: true

# Job to ETL dataset metadata from Searchworks
class SearchworksEtlJob < EtlJob
  include Checkinable

  def perform(query_label:, solr_params: {})
    @query_label = query_label
    dataset_record_set = Extractors::Searchworks.call(list_args: { params: solr_params })
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "SearchworksEtlJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"

    TransformerLoader.call(dataset_record_set:)
  end

  def checkin_key
    "#{self.class.name.underscore}_#{@query_label.downcase}_checkin"
  end
end
