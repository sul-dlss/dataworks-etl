# frozen_string_literal: true

module DataworksMappers
  # Map fields from SDR cocina records to Dataworks metadata
  # rubocop:disable Metrics/ClassLength
  class Sdr < Base
    include ActiveSupport::NumberHelper

    # Generally we should be able to filter contributors using their marcrelator
    # role code, but some data doesn't use the code even when it says it does,
    # so we have to check the role value instead.
    CREATOR_ROLES = ['author', 'authoring entity', 'primary investigator'].freeze
    PUBLISHER_ROLES = %w[publisher].freeze

    def initialize(source:)
      super(source: source.is_a?(Hash) ? Cocina::Models::DROWithMetadata.new(source) : source)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
        related_identifiers:,
        sizes:,
        formats:,
        rights_list:,
        funding_references:,
        related_items:,
        url:,
        access:,
        provider: 'SDR'
      }.compact_blank
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    # Not mapping alternative/subtitles at the moment
    def titles(element = source.description.title)
      return [] if element.blank?

      [
        { title: Cocina::Models::Builders::TitleBuilder.full_title(element).first }
      ]
    end

    # Druid is always present, but DOI may not be
    def identifiers
      [
        { identifier: source.externalIdentifier, identifier_type: 'DRUID' }
      ].tap do |ids|
        ids.push(doi) if doi.present?
      end
    end

    # DOI can be stored in two places, so check both
    def doi
      # If it's here, it is not in URL form
      if source.identification.doi.present?
        return {
          identifier: source.identification.doi,
          identifier_type: 'DOI'
        }
      end

      return if (doi = source.description.identifier.find { |id| id.type == 'DOI' }).nil?

      # If it's here, it is in URL form
      {
        identifier: id_from_url(doi.value),
        identifier_type: 'DOI'
      }
    end

    # Strip the URL prefix from a DOI (or other identifier) and return just the ID
    def id_from_url(id_url)
      URI(id_url).path.delete_prefix('/')
    end

    def creators
      source.description.contributor.map do |c|
        cocina_contributor_struct(c) if c.role.any? { |r| CREATOR_ROLES.include? r.value.downcase }
      end.compact
    end

    def contributors
      source.description.contributor.map do |c|
        cocina_contributor_struct(c) unless c.role.any? { |r| CREATOR_ROLES.include? r.value.downcase }
      end.compact
    end

    def publisher
      source.description.event.flat_map(&:contributor).map do |c|
        { name: c.name.first.value } if c.role.any? { |r| PUBLISHER_ROLES.include? r.value.downcase }
      end
    end

    # Use the earliest year from a publication date, or failing that, the
    # earliest year from a creation date. If no dates at all, fall back to the
    # year the source metadata was created.
    def publication_year
      first_pub_year = date_values_by_type('Issued').map { |d| Date.edtf(d)&.year }.compact.min
      created_year = date_values_by_type('Created').map { |d| Date.edtf(d)&.year }.compact.min

      (first_pub_year || created_year || source.created.year).to_s
    end

    def language
      source.description.language.pick(:code)
    end

    def subjects
      source.description.subject.filter { |s| s.type == 'topic' }.map do |subject|
        { subject: subject.value }
      end
    end

    def descriptions
      source.description.note.map { |note| description_struct(note) }.compact
    end

    # rubocop:disable Metrics/MethodLength, Style/EmptyElse
    # Convert a Cocina note to DataCite structured data
    def description_struct(note)
      return if note.value.blank?

      description_type = case note.type
                         when 'abstract'
                           'Abstract'
                         when 'numbering'
                           'SeriesInformation'
                         when 'table of contents'
                           'TableOfContents'
                         when 'technical note'
                           'TechnicalInfo'
                         else
                           nil
                         end

      return if description_type.nil?

      {
        description: note.value,
        description_type:
      }
    end
    # rubocop:enable Metrics/MethodLength, Style/EmptyElse

    def dates
      source.description.event.flat_map(&:date).map { |d| event_date_struct(d) }.compact
    end

    # This is the data version, not the (metadata) SDR version or user version
    def version
      source.description.note.filter { |n| n.type == 'version' }.map(&:value).compact.first
    end

    # Related resources with an identifier go here
    def related_identifiers
      source.description.relatedResource.map { |r| related_identifier_struct(r) }.compact
    end

    # Related items are used for things that don't have an identifier, often
    # user-provided links that only have a title and URL.
    def related_items
      source.description.relatedResource.map { |r| related_item_struct(r) }.compact
    end

    # Sizes could be anything, but in example data were rarely populated, and we
    # mostly want a bytes estimate for download. If there's nothing, sum the
    # sizes of all files as a fallback.
    # rubocop:disable Metrics/AbcSize
    def sizes
      desc_sizes = source.description.form.filter { |f| f.type == 'extent' }.map(&:value).compact
      return desc_sizes if desc_sizes.any?

      total_size = source.structural.contains.flat_map do |fs|
        fs.structural.contains.map(&:size)
      end.compact_blank.sum
      desc_sizes.push(number_to_human_size(total_size)) if total_size

      desc_sizes
    end
    # rubocop:enable Metrics/AbcSize

    # Also available via source.description.form, but rarely populated there.
    # This approach actually inspects the MIME types of every file instead.
    def formats
      source.structural.contains.flat_map { |fs| fs.structural.contains.map(&:hasMimeType) }.compact_blank.uniq
    end

    # We only ever have one rights statement even though field is an array
    def rights_list
      [
        {
          rights: source.access.useAndReproductionStatement,
          rights_uri: source.access.license
        }.compact_blank
      ]
    end

    # Our data collapses both funder name and award name into the "name" field
    # here, and it's not straightforward to separate, so we just keep the whole
    # thing as funder_name and ignore award_number.
    # rubocop:disable Metrics/CyclomaticComplexity
    def funding_references
      source.description.contributor.map do |c|
        next unless c.role.any? { |r| r.value.downcase == 'funder' }

        {
          funder_name: c.name&.first&.value,
          funder_identifier: c.identifier&.first&.value
        }.compact_blank
      end.compact
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # We use the PURL as the canonical URL
    def url
      source.description.purl
    end

    def access
      source.access.download == 'world' ? 'Public' : 'Restricted'
    end

    # Get the actual date values for all dates of a given type
    def date_values_by_type(type)
      dates.filter { |d| d[:date_type] == type }.pluck(:date)
    end

    # Convert marcrelator code to DataCite contributor type (non-creator)
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    def marc_relator_to_contributor_type(role)
      return unless role.code
      return unless role.source&.code == 'marcrelator'

      case role.code
      when 'aut'
        nil # Creator is handled separately
      when 'mdc', 'prc'
        'ContactPerson'
      when 'col'
        'DataCollector'
      when 'cur'
        'DataCurator'
      when 'dtm'
        'DataManager'
      when 'dst'
        'Distributor'
      when 'edt'
        'Editor'
      when 'his'
        'HostingInstitution'
      when 'pro'
        'Producer'
      when 'pdr'
        'ProjectLeader'
      when 'res'
        'Researcher'
      when 'cph'
        'RightsHolder'
      when 'spn'
        'Sponsor'
      when 'trl'
        'Translator'
      else
        'Other'
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

    # Convert a Cocina event date to DataCite structured data
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    def event_date_struct(date)
      date_value = date.value || date.structuredValue.first.value
      date_information = date.note.map(&:value)
      date_type = case date.type
                  when 'copyright'
                    'Copyrighted'
                  when 'collection'
                    'Collected'
                  when 'coverage'
                    'Coverage'
                  when 'creation', 'production', 'generation'
                    'Created'
                  when 'submission'
                    'Submitted'
                  when 'publication', 'release', 'distribution'
                    'Issued'
                  when 'modification'
                    'Updated'
                  when 'validity'
                    'Valid'
                  when 'withdrawal'
                    'Withdrawn'
                  else
                    date_information.unshift(date.type)
                    'Other'
                  end

      {
        date: date_value,
        date_type:,
        date_information: date_information.compact_blank.presence&.join('; ')
      }.compact_blank
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

    # Convert Cocina::Models::DescriptiveValue person to DataCite structured data
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def cocina_contributor_struct(contributor)
      return if (name = contributor.name.first).blank?

      # Cocina supports many other types but they're all effectively organizational
      name_type = contributor.type == 'person' ? 'Personal' : 'Organizational'

      struct = {
        name: name.value,
        name_type:
      }

      contributor_type = marc_relator_to_contributor_type(contributor.role.first) if contributor.role.any?
      struct.merge!({ contributor_type: }.compact)

      # Given/family names sometimes present as structuredValue
      if name.structuredValue.present?
        given_name = name.structuredValue.filter { |v| v.type == 'forename' }.first
        family_name = name.structuredValue.filter { |v| v.type == 'surname' }.first

        struct.merge!(
          {
            given_name: given_name&.value,
            family_name: family_name&.value
          }.compact
        )
      end

      # Sometimes the name has no value but does have split out given/family names
      if !struct[:name] && (struct[:given_name] || struct[:family_name])
        struct[:name] = [struct[:family_name], struct[:given_name]].compact.join(', ')
      end

      # Identifiers, if present. Sometimes there is a field 'id' with the full
      # link (e.g. for ORCID), sometimes there's just "value" with the ID part
      # and you need to add it to the source URI to construct the full link.
      if contributor.identifier.any?
        struct[:name_identifiers] = contributor.identifier.map do |id|
          name_identifier = id.uri || [id.source&.uri, id.value].compact.join('/')
          next unless name_identifier

          # Sometimes we set the type to 'ORCID' but don't provide a URI
          name_identifier_scheme = id.type
          scheme_uri = id.source&.uri || ('https://orcid.org/' if name_identifier_scheme == 'ORCID')

          {
            name_identifier:,
            name_identifier_scheme:,
            scheme_uri:
          }.compact_blank
        end.compact_blank
      end

      # Affiliations are in the note field
      if (affiliations = contributor.note.filter { |n| n.type == 'affiliation' }).any?
        struct[:affiliation] = affiliations.map do |affiliation|
          affiliation_struct = { name: affiliation.value }

          # Affiliations can also have identifiers, but only one
          if affiliation.identifier.any?
            affiliation_id = affiliation.identifier.first
            affiliation_struct[:affiliation_identifier] = affiliation_id.uri
            affiliation_struct[:affiliation_identifier_scheme] = affiliation_id.type
            affiliation_struct[:scheme_uri] = affiliation_id.source&.uri
          end

          affiliation_struct.compact_blank
        end
      end

      struct
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Map a Cocina relatedResource type to DataCite relation type
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    def related_resource_type(resource)
      case resource.type
      when 'derived from'
        'IsDerivedFrom'
      when 'has other format'
        'isVariantFormOf'
      when 'preceded by', 'has original version'
        'IsNewVersionOf'
      when 'succeeded by'
        'IsPreviousVersionOf'
      when 'has version'
        'IsVersionOf'
      when 'has part'
        'HasPart'
      when 'is identical to'
        'IsIdenticalTo'
      when 'in series'
        'IsPartOf'
      when 'referenced by'
        'IsReferencedBy'
      when 'references'
        'References'
      when 'reviewed by'
        'IsReviewedBy'
      when 'source of'
        'IsSourceOf'
      when 'supplemented by'
        'IsSupplementedBy'
      when 'supplement to'
        'IsSupplementTo'
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

    # Convert a Cocina relatedResource with ID to DataCite structured data
    def related_identifier_struct(resource)
      # If no ID, it will become a related item instead
      resource_id = resource.identifier.first
      return if resource_id.blank?

      {
        relation_type: related_resource_type(resource),
        related_identifier: id_from_url(resource_id.value),
        related_identifier_type: resource_id.type
      }.compact_blank
    end

    # Convert a Cocina relatedResource without ID to DataCite structured data
    def related_item_struct(resource)
      # If we have an ID, it will become a related identifier instead
      resource_id = resource.identifier.first
      return if resource_id.present?

      # Check if we have a URL, which is the only required field
      return if (url = resource.access&.url&.first).blank?

      {
        titles: titles(resource.title),
        related_item_type: related_resource_type(resource),
        related_item_identifier: {
          related_item_identifier: url.value,
          related_item_identifier_type: 'URL'
        }
      }.compact_blank
    end

    # rubocop:enable Metrics/ClassLength
  end
end
