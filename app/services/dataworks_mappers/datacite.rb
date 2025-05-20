# frozen_string_literal: true

module DataworksMappers
  # Map from Datacite metadata to Dataworks metadata
  class Datacite < Base # rubocop:disable Metrics/ClassLength
    def perform_map # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      {
        creators: people_or_organizations_for(attrs[:creators]),
        titles:,
        publisher:,
        publication_year: attrs[:publicationYear]&.to_s,
        subjects:,
        contributors: people_or_organizations_for(attrs[:contributors]),
        descriptions:,
        dates:,
        language: attrs[:language],
        version: attrs[:version],
        identifiers:,
        related_identifiers:,
        sizes: attrs[:sizes],
        formats: attrs[:formats],
        rights_list:,
        funding_references:,
        url: attrs[:url],
        access: 'Public', # TODO: Hardcoded for now, but needs additional consideration
        provider: 'DataCite',
        geo_locations:
      }.compact_blank
    end

    private

    def attrs
      source.dig(:data, :attributes)
    end

    def titles
      attrs[:titles].map do |title|
        {
          title: title[:title],
          title_type: title[:titleType]
        }.compact
      end
    end

    def people_or_organizations_for(people_or_organizations)
      people_or_organizations.map do |person_or_organization|
        Datacite::PersonOrOrganization.call(person_or_organization: person_or_organization)
      end
    end

    def publisher
      {
        name: attrs.dig(:publisher, :name),
        publisher_identifier: attrs.dig(:publisher, :publisherIdentifier),
        publisher_identifier_scheme: attrs.dig(:publisher, :publisherIdentifierScheme)
      }.compact
    end

    def subjects
      attrs[:subjects].map do |subject|
        {
          subject: subject[:subject],
          subject_scheme: subject[:subjectScheme],
          value_uri: subject[:valueUri].presence
        }.compact
      end
    end

    def descriptions
      attrs[:descriptions].filter_map do |description|
        next if description[:description].blank?

        {
          description: description[:description],
          description_type: description[:descriptionType]
        }.compact
      end
    end

    def dates
      attrs[:dates].map do |date|
        {
          date: cleanup_date(date[:date]),
          date_type: date[:dateType]
        }.compact
      end
    end

    def cleanup_date(date)
      date.strip!
      date.sub!(' to ', '/')
      date << 'Z' if date.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/)
      date
    end

    def geo_locations
      return unless attrs[:geoLocations]

      attrs[:geoLocations].filter_map do |geo_location|
        next if geo_location[:geoLocationPlace].blank?

        {
          geo_location_place: geo_location[:geoLocationPlace]
        }.compact
      end
    end

    def identifiers
      [{ identifier: attrs[:doi], identifier_type: 'DOI' }].tap do |identifiers|
        attrs[:identifiers].filter_map do |identifier|
          next if identifier[:identifier].blank?

          identifiers << { identifier: identifier[:identifier], identifier_type: identifier[:identifierType] }
        end
      end
    end

    def rights_list
      attrs[:rightsList].map do |right|
        {
          rights: right[:rights],
          rights_uri: right[:rightsUri].presence,
          rights_identifier: right[:rightsIdentifier],
          rights_identifier_scheme: right[:rightsIdentifierScheme]
        }.compact
      end
    end

    def funding_references
      attrs[:fundingReferences].map do |funding_reference|
        {
          funder_name: funding_reference[:funderName],
          funder_identifier: funding_reference[:funderIdentifier],
          funder_identifier_type: funding_reference[:funderIdentifierType],
          award_number: funding_reference[:awardNumber],
          award_uri: funding_reference[:awardUri].presence,
          award_title: funding_reference[:awardTitle]
        }.compact
      end
    end

    def related_identifiers
      attrs[:relatedIdentifiers].filter_map do |related_identifier|
        next if related_identifier[:relatedIdentifier].blank?

        {
          related_identifier: related_identifier[:relatedIdentifier],
          relation_type: related_identifier[:relationType],
          resource_type_general: related_identifier[:resourceTypeGeneral],
          related_identifier_type: related_identifier[:relatedIdentifierType]
        }.compact
      end
    end
  end
end
