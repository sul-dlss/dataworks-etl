# frozen_string_literal: true

# Job to ETL dataset metadata from DataCite
class DataciteEtlJob < EtlJob
  include Checkinable

  def perform(affiliation: nil, client_id: nil)
    @organization = affiliation || client_id
    dataset_record_set = Extractors::Datacite.call(affiliation:, client_id:)
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "DataciteEtlJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"

    TransformerLoader.call(dataset_record_set:)
  end

  def checkin_key
    "#{self.class.name.underscore}_#{organization}_checkin"
  end

  private

  def organization
    return unless @organization

    @organization.gsub(/[.\s]/, '_').downcase
  end
end
