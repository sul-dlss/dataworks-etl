# frozen_string_literal: true

module DataworksMappers
  # Map from OpenAlex metadata to Dataworks metadata
  class OpenAlex < Base # rubocop:disable Metrics/ClassLength
    IDENTIFIER_TYPES = {
      'openalex' => 'OpenAlex',
      'doi' => 'DOI'
    }.freeze

    def perform_map
      {
        identifiers:,
        titles:,
        creators:,
        publication_year: source[:publication_year].to_s,
        url: source.dig(:primary_location, :landing_page_url),
        access:,
        provider: 'OpenAlex',
        language: source[:language],
        rights_list:,
        subjects:,
        funding_references:,
        related_identifiers:
      }.compact_blank
    end

    private

    def access
      return 'Restricted' unless source.dig(:primary_location, :is_oa)

      'Public'
    end

    def affiliations_for(institutions)
      return unless institutions

      Array(institutions).map do |institution|
        {
          affiliation_identifier: institution[:ror],
          affiliation_identifier_scheme: 'ROR',
          name: institution[:display_name]
        }.compact
      end
    end

    def creators
      return unless source[:authorships]

      Array(source[:authorships]).map do |author|
        {
          name: author.dig(:author, :display_name),
          name_identifiers: name_identifiers_for(author[:author]),
          affiliation: affiliations_for(author[:institutions])
        }.compact_blank
      end
    end

    def funding_references
      return if source[:grants].blank?

      Array(source[:grants]).map do |grant|
        {
          funder_name: grant[:funder_display_name],
          funder_identifier: grant[:funder],
          funder_identifier_type: 'OpenAlex',
          award_number: grant[:award_id]
        }.compact
      end
    end

    def identifiers
      return unless source[:ids]

      Array(source[:ids]).map do |identifier_type, identifier|
        next unless IDENTIFIER_TYPES.key?(identifier_type)

        {
          identifier:,
          identifier_type: IDENTIFIER_TYPES[identifier_type]
        }
      end.compact_blank
    end

    def name_identifiers_for(author)
      return unless author[:id]

      [
        {
          name_identifier: author[:id],
          name_identifier_scheme: 'OpenAlex'
        }
      ].tap do |name_identifier|
        next unless author[:orcid]

        name_identifier << {
          name_identifier: author[:orcid],
          name_identifier_scheme: 'ORCID'
        }
      end
    end

    def related_identifiers
      return if source[:referenced_works].blank?

      Array(source[:referenced_works]).map do |related_identifier|
        {
          related_identifier: related_identifier,
          related_identifier_type: 'OpenAlex'
        }.compact
      end
    end

    def rights_list
      return unless source.dig(:primary_location, :license_id)

      [{ rights_uri: source.dig(:primary_location, :license_id) }]
    end

    def subjects
      return unless source[:topics]

      Array(source[:topics]).map do |topic|
        {
          subject: topic[:display_name]
        }.compact
      end
    end

    def titles
      return unless source[:title] || source[:display_name]

      [{ title: source[:title] || source[:display_name] }]
    end
  end
end
