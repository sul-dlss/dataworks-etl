# frozen_string_literal: true

require 'csv'

# Loads Stanford author (RIALTO affiliation) data from a CSV export into the
# StanfordAuthor table, importing in batches for efficiency. Callers are
# responsible for clearing existing records first if a full replace is desired.
class StanfordAuthorLoader
  BATCH_SIZE = 5000

  def self.call(...)
    new(...).call
  end

  # @param file_path [String, Pathname] path to the author CSV to import
  def initialize(file_path:)
    @file_path = file_path
  end

  # @return [Integer] the number of rows imported
  def call
    import_records = []
    total = 0

    CSV.foreach(file_path, headers: true) do |row|
      total += 1
      import_records << build_author(row)
      next unless import_records.length == BATCH_SIZE

      StanfordAuthor.import(import_records)
      import_records = []
    end

    StanfordAuthor.import(import_records) if import_records.any?
    total
  end

  private

  attr_reader :file_path

  def build_author(row)
    StanfordAuthor.new(
      sunet_id: row['sunetid'],
      cap_profile_id: row['cap_profile_id'],
      full_name: row['full_name'],
      first_name: row['first_name'],
      last_name: row['last_name'],
      orcid: row['orcidid'],
      email: row['email'],
      active: row['active']&.downcase == 'true',
      departments: row['all_departments']&.split('|')
    )
  end
end
