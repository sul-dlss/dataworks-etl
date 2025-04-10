# frozen_string_literal: true

module DataworksMappers
  # Map from Zenodo metadata to Dataworks metadata
  class Zenodo < Base # rubocop:disable Metrics/ClassLength
    # Map from Zenodo related identifier schemes to Dataworks related identifier types
    RELATED_IDENTIFIER_MAP = {
      'arxiv' => 'arXiv',
      'doi' => 'DOI',
      'ean8' => 'EAN8',
      'issn' => 'ISSN',
      'lsid' => 'LSID',
      'pmid' => 'PMID',
      'url' => 'URL'
    }.freeze

    def perform_map
      {
        identifiers:,
        titles: [{ title: metadata[:title] }],
        descriptions:,
        creators:,
        publication_year:,
        subjects:,
        dates:,
        related_identifiers:,
        sizes:,
        version: metadata[:version],
        rights_list:,
        url: source[:doi_url],
        funding_references:,
        access:,
        provider: 'Zenodo'
      }.compact_blank
    end

    private

    def metadata
      source[:metadata]
    end

    def identifiers
      [{ identifier: source[:id].to_s, identifier_type: 'ZenodoId' }].tap do |identifiers|
        identifiers << { identifier: source[:doi], identifier_type: 'DOI' } if source[:doi].present?
      end
    end

    def descriptions
      return if metadata[:description].blank?

      [
        {
          description: metadata[:description],
          description_type: 'Abstract'
        }
      ]
    end

    def creators
      Array(metadata[:creators]).map do |creator|
        { name: creator[:name], name_type: 'Personal' }.tap do |attrs|
          attrs[:affiliation] = [{ name: creator[:affiliation] }] if creator[:affiliation].present?
          if creator[:orcid].present?
            attrs[:name_identifiers] = [{ name_identifier: creator[:orcid], name_identifier_scheme: 'ORCID' }]
          end
        end
      end
    end

    def publication_year
      metadata[:publication_date].slice(0..3) if metadata[:publication_date].present?
    end

    def subjects
      Array(metadata[:keywords]).map { |keyword| { subject: keyword } }
    end

    def dates
      [{ date: metadata[:publication_date], date_type: 'Issued' }]
    end

    def related_identifiers
      Array(metadata[:related_identifiers]).filter_map do |related_identifier|
        next if related_identifier[:scheme] == 'other'

        {
          related_identifier: related_identifier[:identifier],
          relation_type: relation_type_for(related_identifier[:relation]),
          related_identifier_type: RELATED_IDENTIFIER_MAP.fetch(related_identifier[:scheme],
                                                                related_identifier[:scheme])
        }.compact
      end
    end

    def relation_type_for(relation)
      # Zenodo uses different capiralization for relation types
      relation[0].upcase + relation[1..]
    end

    def sizes
      ["#{source[:files].pluck(:size).sum} bytes"]
    end

    def rights_list
      rights_identifier = metadata.dig(:license, :id)
      return if rights_identifier.blank?

      # Zenodo has its own rights list. See https://zenodo.org/api/vocabularies/licenses
      [{ rights_identifier:, rights_identifier_scheme: 'zenodo' }]
    end

    def access
      if metadata[:access_right] == 'open'
        'Public'
      else
        'Restricted'
      end
    end

    def funding_references
      Array(metadata[:grants]).map do |grant|
        {
          award_number: grant[:code],
          award_title: grant[:title]
        }.compact.merge(funder_attrs_for(grant[:funder]))
      end
    end

    def funder_attrs_for(funder)
      return {} if funder.blank?

      {
        funder_name: funder[:name]
      }.compact.tap do |attrs|
        if funder[:doi].present?
          attrs[:funder_identifier] = funder[:doi]
          attrs[:funder_identifier_type] = 'DOI'
        end
      end
    end
  end
end
