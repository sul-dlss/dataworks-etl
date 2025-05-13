# frozen_string_literal: true

module DataworksMappers
  # Map fields from SearchWorks solr docs to Dataworks metadata
  # rubocop:disable Metrics/ClassLength
  class Searchworks < Base
    def doi_identifier
      return unless doi_url

      { identifier: URI(doi_url).path.delete_prefix('/'), identifier_type: 'DOI' }
    end

    private

    def perform_map
      {
        creators:,
        titles:,
        publisher:,
        publication_year:,
        subjects:,
        contributors:,
        descriptions:,
        dates:,
        language:,
        version:,
        identifiers:,
        funding_references:,
        url:,
        access:,
        provider: 'SearchWorks'
      }.compact_blank
    end

    def identifiers
      [searchworks_identifier, doi_identifier].compact
    end

    def searchworks_identifier
      { identifier: source['id'], identifier_type: 'SearchWorksReference' }
    end

    def doi_url
      return unless urls&.any?

      urls.find { |u| u.include? 'doi.org' }
    end

    def urls
      restricted? ? source['url_restricted'] : source['url_fulltext']
    end

    def url
      urls&.first
    end

    def descriptions
      return unless (description = source.dig('summary_display', 0))

      [
        { description:, description_type: 'Abstract' }
      ]
    end

    # For items with MARC, SearchWorks often joins the 245$b (subtitle) and
    # 245$h (medium) into title_display. We don't want this because everything
    # will have "[electronic resource]" in the title, so if MARC is available,
    # we separate out the titles ourselves.
    # rubocop:disable Metrics/AbcSize
    def titles
      return [{ title: source['title_display'] }] if marc_record.blank?

      titles = [{ title: marc_record['245']['a'] }] # main title
      titles << { title: marc_record['245']['b'], title_type: 'Subtitle' } if marc_record['245']['b'].present?
      titles << { title: marc_record['246']['a'], title_type: 'AlternativeTitle' } if marc_record['246'].present?

      titles
    end
    # rubocop:enable Metrics/AbcSize

    # Other fields like topic_display include additional topics specific to the
    # item; we want the more common/generic subject headings only
    def subjects
      source['topic_facet']&.map do |subject|
        { subject: }
      end
    end

    # SearchWorks has fields for publication country and date, but the actual
    # publisher name is concatenated with the place of publication and sometimes
    # other info as well. We need to go to the MARC to get it cleanly.
    def publisher
      return unless (name = marc_record&.[]('260')&.[]('b'))

      { name: }
    end

    # Structured data is only available via the MARC
    def creators
      return unless marc_record

      [].tap do |creators|
        marc_record.fields.each_by_tag(%w[100 110]) do |field|
          creators << marc_contributor_struct(field)
        end
      end
    end

    # Structured data is only available via the MARC
    def contributors
      return unless marc_record

      [].tap do |contributors|
        marc_record.fields.each_by_tag(%w[700 710]) do |field|
          contributors << marc_contributor_struct(field)
        end
      end
    end

    # Structured data is only available via the MARC
    def funding_references
      return unless marc_record

      [].tap do |references|
        marc_record.fields.each_by_tag(%w[536]) do |field|
          next unless field['a']

          references << {
            funder_name: field['a'],
            award_number: field['c']
          }.compact_blank
        end
      end
    end

    def access
      restricted? ? 'Restricted' : 'Public'
    end

    def publication_year
      source['pub_year_tisim']&.first&.to_s
    end

    def restricted?
      source['url_restricted'].present?
    end

    # These date fields in SearchWorks can come from both MARC and MODS/SDR
    # metadata, although only pub year is common.
    def dates
      all_dates = source['pub_year_tisim']&.map do |date|
        { date: date.to_s, date_type: 'Issued' }
      end

      if (created_date = source['production_year_isi'].presence)
        all_dates << { date: created_date.to_s, date_type: 'Created' }
      end

      if (copyright_date = source['copyright_year_isi'].presence)
        all_dates << { date: copyright_date.to_s, date_type: 'Copyrighted' }
      end

      all_dates
    end

    # SearchWorks has an array of names like ["English", "Spanish"]; we want the
    # two-letter ISO-639 code and can only pick one, so we take the first.
    def language
      source['language']&.map do |lang|
        ISO_639.find_by_english_name(lang)&.alpha2 # rubocop:disable Rails/DynamicFindBy
      end&.compact&.first
    end

    # This is only available via the MARC. SDR items with user versions will
    # get indexed using the SDR extractor pathway instead.
    def version
      marc_record&.[]('251')&.[]('a')
    end

    def marc_record
      return unless source['marc_json_struct']&.any?

      @marc_record ||= MARC::Record.new_from_hash(JSON.parse(source['marc_json_struct'][0]))
    end

    # Convert a MARC creator or contributor to DataCite structured data.
    # SearchWorks often collapses 100/700$u (affiliation) into the person's
    # name in author_struct, so where MARC is available we split it out here.
    def marc_contributor_struct(field)
      return unless field['a']

      name_type = if %w[100 700].include? field.tag
                    'Personal'
                  elsif %w[110 710].include? field.tag
                    'Organizational'
                  else
                    raise DataworksMappers::MappingError "Can't map MARC field #{field.tag} to contributor"
                  end

      contributor = {
        name: field['a'],
        name_type:
      }

      return contributor unless field['u']

      contributor[:affiliation] = [{
        name: field['u']
      }]

      contributor
    end
  end
  # rubocop:enable Metrics/ClassLength
end
