# frozen_string_literal: true

module DataworksMappers
  # Map fields from SearchWorks solr docs to Dataworks metadata
  class Searchworks < Base
    def doi_identifier
      return unless doi_url

      { identifier: URI(doi_url).path.delete_prefix('/'), identifier_type: 'DOI' }
    end

    private

    def perform_map
      {
        identifiers:,
        creators:,
        titles:,
        publication_year:,
        subjects:,
        contributors:,
        # dates:,
        # language:,
        # version:,
        # related_identifiers:,
        # sizes:,
        # formats:,
        provider: 'SearchWorks',
        descriptions:,
        url:,
        access:
      }.compact_blank
    end

    def identifiers
      [searchworks_identifier, doi_identifier].compact
    end

    def searchworks_identifier
      { identifier: source['id'], identifier_type: 'searchworks_reference' }
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

    def titles
      [
        { title: source['title_display'] }
      ]
    end

    def subjects
      source['topic_facet']&.map do |subject|
        { subject: subject }
      end
    end

    def creators
      [].tap do |creators|
        marc_record.fields.each_by_tag(%w[100 110]) do |field|
          creators << marc_contributor_struct(field)
        end
      end
    end

    def contributors
      [].tap do |contributors|
        marc_record.fields.each_by_tag(%w[700 710]) do |field|
          contributors << marc_contributor_struct(field)
        end
      end
    end

    def access
      restricted? ? 'Restricted' : 'Public'
    end

    def publication_year
      source['pub_year_tisim'].first.to_s
    end

    def restricted?
      source['url_restricted'].present?
    end

    def marc_record
      return unless source['marc_json_struct']&.any?

      @marc_record ||= MARC::Record.new_from_hash(JSON.parse(source['marc_json_struct'][0]))
    end

    # Convert a MARC creator or contributor to DataCite structured data
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
end
