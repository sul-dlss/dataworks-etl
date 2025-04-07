# frozen_string_literal: true

# Base class for jobs to extract dataset metadata
class ExtractJob < ApplicationJob
  # Sets the job id on the DatasetSourceSet
  around_perform do |job, block|
    # perform() must return a DatasetSourceSet
    dataset_source_set = block.call
    dataset_source_set.update!(job_id: job.job_id)
  end
end
