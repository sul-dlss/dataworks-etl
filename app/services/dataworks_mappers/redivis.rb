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
      { key: :methodologyMarkdown, type: 'Methods' }
    ].freeze

    def perform_map
      {
        # source_id: source[:qualifiedReference],
        titles: [{ title: source[:name] }],
        creators: [{ name: source[:owner][:fullName] }]
        # resource_type: 'Dataset',
        # identifier: source[:doi],
        # identifier_type: 'DOI',
        # landing_page: source[:url],
        # access: source[:publicAccessLevel],
        # size: source[:tableCount], # : source[:totalNumBytes],
        # variables: tables.variables.name....
        # tags: source[:tags].map { |tag| { tag: tag[:name] } }
      }.merge(optional_params)
    end

    private

    def optional_params
      {
        doi: source[:doi],
        descriptions:,
        dates:,
        version: source[:version][:tag]
      }
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
  end
end
