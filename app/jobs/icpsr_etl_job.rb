# frozen_string_literal: true

# Job to ETL dataset metadata from ICPSR via Searchworks
class IcpsrEtlJob < EtlJob
  include Checkinable

  # Search criteria for ICPSR datasets in Searchworks. We look for ICPSR listed
  # as an author, and filter for datasets that have an online access URL.
  def self.solr_params
    {
      q: 'Inter-university Consortium for Political and Social Research.',
      search_field: 'search_author',
      fq: [
        'access_facet:Online',
        'format_main_ssim:Dataset'
      ]
    }
  end

  def perform
    dataset_record_set = Extractors::Searchworks.call(list_args: { params: IcpsrEtlJob.solr_params })
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "IcpsrEtlJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"

    TransformerLoader.call(dataset_record_set:)
  end
end
