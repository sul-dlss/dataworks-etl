# frozen_string_literal: true

module DataworksMappers
  class Datacite
    # Map a person or organization from Datacite metadata to Dataworks metadata
    class PersonOrOrganization
      AFFILIATION_IDENTIFIER_SCHEME_MAP = {
        'https://ror.org' => 'ROR'
      }.freeze

      def self.call(...)
        new(...).call
      end

      def initialize(person_or_organization:)
        @person_or_organization = person_or_organization
      end

      def call
        {
          name:,
          name_type: person_or_organization[:nameType],
          contributor_type: person_or_organization[:contributorType],
          given_name: person_or_organization[:givenName],
          family_name: person_or_organization[:familyName],
          affiliation:,
          name_identifiers:
        }.compact_blank
      end

      private

      attr_reader :person_or_organization

      def name
        return person_or_organization[:name] if person_or_organization[:name].present?
        return if person_or_organization[:givenName].blank? || person_or_organization[:familyName].blank?

        "#{person_or_organization[:familyName]}, #{person_or_organization[:givenName]}"
      end

      def affiliation
        person_or_organization[:affiliation]&.filter_map do |affiliation|
          next if other_scheme?(affiliation[:affiliationIdentifierScheme])

          {
            name: affiliation[:name],
            affiliation_identifier: affiliation[:affiliationIdentifier],
            affiliation_identifier_scheme: affiliation_identifier_scheme_for(affiliation)
          }.compact
        end
      end

      def affiliation_identifier_scheme_for(affiliation)
        # This allows cleaning up some incorrect schemes in the Datacite metadata
        scheme = affiliation[:affiliationIdentifierScheme] || affiliation[:schemeUri]
        AFFILIATION_IDENTIFIER_SCHEME_MAP.fetch(scheme, scheme)
      end

      def name_identifiers
        person_or_organization[:nameIdentifiers]&.filter_map do |name_identifier|
          next if other_scheme?(name_identifier[:nameIdentifierScheme])

          {
            name_identifier: name_identifier[:nameIdentifier],
            name_identifier_scheme: name_identifier[:nameIdentifierScheme]
          }.compact
        end
      end

      def other_scheme?(scheme)
        scheme&.downcase == 'other'
      end
    end
  end
end
