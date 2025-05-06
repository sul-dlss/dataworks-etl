# frozen_string_literal: true

# Job to extract dataset metadata from Redivis
class RedivisExtractJob < ExtractJob
  include Checkinable

  def perform(organization:)
    @organization = organization
    dataset_record_set = Extractors::Redivis.call(organization:)
    dataset_record_set.update!(job_id: @job_id) if @job_id

    Rails.logger.info "RedivisExtractJob complete: DatasetRecordSet #{dataset_record_set.id} - " \
                      "job #{dataset_record_set.job_id} - #{dataset_record_set.provider} - " \
                      "#{dataset_record_set.dataset_records.count} datasets"
  end

  def checkin_key
    "#{self.class.name.underscore}_#{@organization.downcase}_checkin"
  end
end
