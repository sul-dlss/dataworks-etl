# frozen_string_literal: true

# Base class for jobs to perform extract
class ExtractJob < ApplicationJob
  # Sets the job id
  before_perform do |job|
    @job_id = job.job_id
  end
end
