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

    # Convert a MARC author or contributor to DataCite structured data
    def marc_to_contributor(field, name_type:)
      return unless field['a']

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

    def creator_people
      [].tap do |creators|
        marc_record.fields.each_by_tag(['100']) do |field|
          creators << marc_to_contributor(field, name_type: 'Personal')
        end
      end
    end

    def creator_organizations
      [].tap do |creators|
        marc_record.fields.each_by_tag(['110']) do |field|
          creators << marc_to_contributor(field, name_type: 'Organizational')
        end
      end
    end

    def creators
      creator_people + creator_organizations
    end

    def contributing_people
      [].tap do |contributors|
        marc_record.fields.each_by_tag(['700']) do |field|
          contributors << marc_to_contributor(field, name_type: 'Personal')
        end
      end
    end

    def contributing_organizations
      [].tap do |contributors|
        marc_record.fields.each_by_tag(['710']) do |field|
          contributors << marc_to_contributor(field, name_type: 'Organizational')
        end
      end
    end

    def contributors
      contributing_people + contributing_organizations
    end

    def access
      restricted? ? 'Restricted' : 'Public'
    end

    # These dates are guaranteed to be 4-digit integers, unlike pub_date.
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
  end
  # rubocop:enable Metrics/ClassLength
end
