# frozen_string_literal: true

# Job to refresh Stanford author (RIALTO affiliation) data from the weekly CSV
# export on the shared filesystem. Scheduled in config/recurring.yml.
class RialtoAuthorRefreshJob < ApplicationJob
  include Checkinable

  def perform
    RialtoAuthorRefresh.call
  end
end
