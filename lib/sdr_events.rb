# frozen_string_literal: true

require 'socket'

# Reports indexing events to SDR via message queue
# See: https://github.com/sul-dlss/dor-event-client
# See also the HTTP API: https://sul-dlss.github.io/dor-services-app/#tag/events
class SdrEvents
  class << self
    def configure(
      hostname: Settings.sdr_events.mq.hostname,
      vhost: Settings.sdr_events.mq.vhost,
      username: Settings.sdr_events.mq.username,
      password: Settings.sdr_events.mq.password
    )
      Dor::Event::Client.configure(hostname:, vhost:, username:, password:)
    end

    def enabled?
      ::Settings.sdr_events.enabled
    end

    # Item will be added/updated in the index
    def report_indexing_scheduled(druid, target:)
      create_event(druid:, target:, type: 'indexing_scheduled')
    end

    # Item will be removed from the index (e.g. because of unrelease)
    def report_indexing_deletion_scheduled(druid, target:)
      create_event(druid:, target:, type: 'indexing_deletion_scheduled')
    end

    # Item has missing or inappropriately formatted metadata
    def report_indexing_skipped(druid, target:, message:)
      create_event(druid:, target:, type: 'indexing_skipped', data: { message: })
    end

    # Exception was raised during indexing; provides optional context
    def report_indexing_errored(druid, target:, message:, context: nil)
      create_event(druid:, target:, type: 'indexing_errored', data: { message:, context: }.compact)
    end

    private

    # Generic event creation; prefer more specific methods
    def create_event(druid:, target:, type:, data: {})
      return unless enabled?

      Dor::Event::Client.create(
        druid: "druid:#{druid}",
        type:,
        data: {
          target:,
          host:,
          invoked_by: 'dataworks-indexer'
        }.merge(data)
      )
    end

    # Hostname of the machine running the indexer
    def host
      @host ||= Socket.gethostname
    end
  end
end
