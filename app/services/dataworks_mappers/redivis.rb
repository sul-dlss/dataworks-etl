# frozen_string_literal: true

module DataworksMappers
  # Map from Redivis metadata to Dataworks metadata
  class Redivis < Base
    DATE_TYPES = [
      { key: :temporalRange, type: 'Coverage', epoch: false },
      { key: :createdAt, type: 'Created', epoch: true }
    ].freeze

    DESCRIPTION_TYPES = [
      { key: :description, type: 'Abstract' },
      { key: :methodologyMarkdown, type: 'Methods' },
      { key: :usageMarkdown, type: 'Other' }
    ].freeze

    IDENTIFIER_TYPES = [
      { key: :doi, type: 'DOI' },
      { key: :qualifiedReference, type: 'RedivisReference' }
    ].freeze

    def perform_map
      {
        titles: [{ title: source[:name] }],
        creators: [{ name: source[:owner][:fullName] }],
        publication_year:,
        identifiers:,
        url: source[:url],
        access:,
        provider: 'Redivis'
      }.merge(optional_params)
    end

    private

    def publication_year
      return unless source[:createdAt]

      Time.zone.at(source[:createdAt] / 1000).year.to_s # Redivis timestamps are in milliseconds since epoch
    end

    def identifiers
      [].tap do |identifiers|
        IDENTIFIER_TYPES.each do |identifier_type|
          next unless source[identifier_type[:key]]

          identifiers << { identifier: source[identifier_type[:key]], identifier_type: identifier_type[:type] }
        end
      end
    end

    def access
      source[:publicAccessLevel] == 'none' ? 'Restricted' : 'Public'
    end

    def optional_params
      {
        descriptions:,
        dates:,
        subjects:,
        sizes:,
        version: source[:version][:tag]
      }.compact_blank
    end

    def descriptions
      [].tap do |descriptions|
        DESCRIPTION_TYPES.each do |description_type|
          next unless source[description_type[:key]]

          descriptions << {
            description: source[description_type[:key]],
            description_type: description_type[:type]
          }
        end
      end
    end

    def dates
      [].tap do |dates|
        DATE_TYPES.each do |date_type|
          next unless source[date_type[:key]]

          source_date = source[date_type[:key]]
          source_date = Time.zone.at(source_date / 1000).strftime('%F') if date_type[:epoch]

          dates << {
            date: source_date,
            date_type: date_type[:type]
          }
        end
      end
    end

    def sizes
      return unless source[:totalNumBytes]

      [source[:totalNumBytes].to_s]
    end

    def subjects
      return unless source[:tags]

      source[:tags].map { |tag| { subject: tag[:name] } }
    end
  end
end
