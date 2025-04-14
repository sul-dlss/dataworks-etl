# frozen_string_literal: true

# Concern for checking in with Honeybadger after a job completes.
# To use this, include a setting entry under honeybadger for <underscored
module Checkinable
  extend ActiveSupport::Concern

  included do
    after_perform do |_job|
      key = Settings.honeybadger[checkin_key]
      next unless Rails.env.production? && key

      Faraday.get("https://api.honeybadger.io/v1/check_in/#{key}")
    end
  end

  # @return [String] the key to use for the checkin
  # This can be overridden in the including class, if, for example, the key needs to take into account job parameters.
  def checkin_key
    "#{self.class.name.underscore}_checkin"
  end
end
