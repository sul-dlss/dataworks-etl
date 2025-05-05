# frozen_string_literal: true

# Job for transforming and loading dataset metadata.
class TransformLoadJob < ApplicationJob
  include Checkinable

  # Sets the job id
  before_perform do |job|
    @job_id = job.job_id
  end

  def perform
    TransformerLoader.call(load_id: @job_id)

    Rails.logger.info "TransformLoadJob complete: job #{@job_id}"
  end
end
