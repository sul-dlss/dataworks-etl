# frozen_string_literal: true

# Reloads Stanford author (RIALTO affiliation) data from the weekly CSV export.
# The export lives on a read-only shared filesystem (Weka/NFS) mounted on this
# host, so the CSV is read in place. Driven on a schedule by RialtoAuthorRefreshJob
# (see config/recurring.yml). The delete-and-reload runs in a transaction so
# readers never observe a momentarily empty table, and a failed load rolls back to
# the previously loaded data.
class RialtoAuthorRefresh
  def self.call(...)
    new(...).call
  end

  # @param config [Config::Options] rialto settings: file_path (the CSV path on
  #   the mounted shared filesystem)
  def initialize(config: Settings.rialto)
    @config = config
  end

  # @return [Integer] the number of authors loaded
  def call
    count = StanfordAuthor.transaction do
      StanfordAuthor.delete_all
      StanfordAuthorLoader.call(file_path: config.file_path)
    end

    Rails.logger.info("RialtoAuthorRefresh complete: loaded #{count} authors from #{config.file_path}")
    count
  end

  private

  attr_reader :config
end
