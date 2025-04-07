# frozen_string_literal: true

# Base class for jobs to perform ETL
class EtlJob < ApplicationJob
  # Sets the job id on the DatasetSourceSet
  before_perform do |job|
    @job_id = job.job_id
  end
end
