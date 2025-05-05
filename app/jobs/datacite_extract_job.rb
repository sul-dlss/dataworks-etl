# frozen_string_literal: true

# Job to extract dataset metadata from DataCite
class DataciteExtractJob < ExtractJob
  include Checkinable

  def perform(affiliation: nil, client_id: nil)
    @organization = affiliation || client_id
    dataset_record_set = Extractors::Datacite.call(affiliation:, client_id:)
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "DataciteExtractJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"
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
