# frozen_string_literal: true

module DataworksMappers
  # Map from Redivis metadata to Dataworks metadata
  class Dryad < Base # rubocop:disable Metrics/ClassLength
    DATE_TYPES = [
      { key: :publicationDate, type: 'Issued' },
      { key: :lastModificationDate, type: 'Updated' }
    ].freeze

    DESCRIPTION_TYPES = [
      { key: :abstract, type: 'Abstract' },
      { key: :methods, type: 'Methods' },
      { key: :usageNotes, type: 'Other' }
    ].freeze

    IDENTIFIER_TYPES = [
      { key: :identifier, type: 'DOI' }
    ].freeze

    def perform_map
      {
        titles: [{ title: source[:title] }],
        creators:,
        publication_year:,
        identifiers:,
        url: source[:sharingLink],
        access:,
        provider: 'Dryad',
        descriptions:,
        dates:,
        subjects:,
        sizes:,
        funding_references:,
        rights_list:,
        related_identifiers:,
        version: source[:versionNumber].to_s
      }.compact_blank
    end

    private

    def access
      source[:visibility] == 'public' ? 'Public' : 'Restricted'
    end

    def creators
      Array(source[:authors]).map do |author|
        {
          name: "#{author[:firstName]} #{author[:lastName]}",
          name_type: 'Personal',
          name_identifiers: name_identifiers_for(author),
          affiliation: affiliation_for(author)
        }.compact_blank
      end
    end

    def name_identifiers_for(author)
      return unless author[:orcid]

      [{ name_identifier: author[:orcid], name_identifier_scheme: 'ORCID' }]
    end

    def affiliation_for(author)
      return unless author[:affiliation]

      [{
        name: author[:affiliation],
        affiliation_identifier: author[:affiliationROR],
        affiliation_identifier_scheme: 'ROR'
      }]
    end

    def dates
      [].tap do |dates|
        DATE_TYPES.each do |date_type|
          next unless source[date_type[:key]]

          dates << {
            date: source[date_type[:key]],
            date_type: date_type[:type]
          }
        end
      end
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

    def funding_references
      Array(source[:funders]).map do |funder|
        {
          funder_name: funder[:organization],
          funder_identifier: funder[:identifier],
          funder_identifier_type: funder[:identifierType].upcase,
          award_number: funder[:awardNumber]
        }.compact
      end
    end

    def identifiers
      [].tap do |identifiers|
        IDENTIFIER_TYPES.each do |identifier_type|
          next unless source[identifier_type[:key]]

          identifiers << { identifier: source[identifier_type[:key]], identifier_type: identifier_type[:type] }
        end
      end
    end

    def publication_year
      return unless source[:publicationDate]

      Time.zone.parse(source[:publicationDate]).year.to_s
    end

    def related_identifiers
      return unless source[:relatedPublicationISSN]

      [].tap do |relationship|
        relationship << { related_identifier: source[:relatedPublicationISSN], related_identifier_type: 'ISSN' }
      end
    end

    def rights_list
      return unless source[:license]

      [].tap do |rights|
        rights << { rights_uri: source[:license] }
      end
    end

    def sizes
      return unless source[:storageSize]

      ["#{source[:storageSize]} KB"]
    end

    def subjects
      return unless source[:keywords]

      source[:keywords].map { |tag| { subject: tag } }
    end
  end
end
