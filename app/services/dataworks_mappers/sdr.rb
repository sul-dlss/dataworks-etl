# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module DataworksMappers
  # Map fields from SDR cocina records to Dataworks metadata
  class Sdr < Base
    include ActiveSupport::NumberHelper

    class << self
      # DOI can be stored in two places, so check both
      def doi(source:)
        # If it's here, it is not in URL form
        if (non_url_doi = source.dig('identification', 'doi')).present?
          return non_url_doi
        end

        # If it's here, it is in URL form
        return if (url_doi = source.dig('description', 'identifier')&.find { |id| id['type'] == 'DOI' }).blank?

        id_from_url(url_doi['value'])
      end

      # Strip the URL prefix from a DOI (or other identifier) and return just the ID
      def id_from_url(id_url)
        URI(id_url).path.delete_prefix('/')
      end

      # Can be called from the main object or from related items. Not mapping
      # any alternative titles at the moment.
      def map_titles(source_titles)
        return [] if (title = source_titles.dig(0, 'value')).blank?

        [{ title: }]
      end
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

    def titles
      DataworksMappers::Sdr.map_titles(source.dig('description', 'title'))
    end

    # Druid is always present, but DOI may not be
    def identifiers
      [{ identifier: source['externalIdentifier'], identifier_type: 'DRUID' }].tap do |ids|
        if (doi_id = self.class.doi(source:)).present?
          ids.push({ identifier: doi_id, identifier_type: 'DOI' })
        end
      end
    end

    def all_contributors
      Array(source.dig('description', 'contributor')).map { |c| ContributorMapper.new(c) }
    end

    def creators
      all_contributors.filter(&:creator?).map(&:call)
    end

    def contributors
      all_contributors.reject(&:creator?).map(&:call)
    end

    def publisher
      all_contributors.find(&:publisher?)&.call
    end

    # Use the earliest year from a publication date, or failing that, the
    # earliest year from a creation date. If no dates at all, fall back to the
    # year the source metadata was created.
    def publication_year
      first_pub_year = date_years_by_type('Issued').min
      created_year = date_years_by_type('Created').min

      (first_pub_year || created_year || Time.zone.parse(source['created']).year).to_s
    end

    def language
      Array(source.dig('description', 'language')).pick('code')
    end

    def subjects
      Array(source.dig('description', 'subject')).filter_map { |s| { subject: s['value'] } if s['type'] == 'topic' }
    end

    def descriptions
      Array(source.dig('description', 'note')).map { |note| DescriptionMapper.new(note).call }.compact
    end

    def all_dates
      Array(source.dig('description', 'event')).pluck('date').flatten.map { |d| DateMapper.new(d) }
    end

    def dates
      all_dates.map(&:call).compact
    end

    # NOTE: This is the data version, not the (metadata) SDR version or user version
    def version
      return if (version_notes = source.dig('description', 'version')&.filter { |n| n['type'] == 'version' }).blank?

      version_notes.pluck('value').compact.first
    end

    def related_resources
      source.dig('description', 'relatedResource') || []
    end

    # Related items are used for things that may not have an identifier, often
    # user-provided links that only have a title and URL.
    def related_items
      related_resources.map { |r| RelatedItemMapper.new(r).call }.compact
    end

    # Related resources with an identifier go here
    def related_identifiers
      related_resources.map { |r| RelatedItemMapper.new(r).as_related_identifier }.compact
    end

    # Sizes could be anything, but in example data were rarely populated, and we
    # mostly want a bytes estimate for download. If there's nothing, sum the
    # sizes of all files as a fallback.
    def sizes
      extents = Array(source.dig('description', 'extent')).filter { |f| f['type'] == 'extent' }.pluck('value').compact
      extents.presence || [total_size]
    end

    # Sum the file sizes of all files in the structural metadata as a string.
    def total_size
      sizes_bytes = source.dig('structural', 'contains').flat_map do |fs|
        fs.dig('structural', 'contains')&.pluck('size')
      end.compact_blank

      number_to_human_size(sizes_bytes.sum)
    end

    # Example data rarely had this populated, so we fall back to MIME types
    def formats
      forms = Array(source.dig('description', 'form')).filter { |f| f['type'] == 'form' }.pluck('value').compact
      forms.presence || mime_types
    end

    # Get the unique MIME types from the structural metadata.
    def mime_types
      struct_mime_types = source.dig('structural', 'contains').flat_map do |fs|
        fs.dig('structural', 'contains')&.pluck('hasMimeType')
      end.compact_blank

      struct_mime_types.uniq
    end

    # We only ever have one rights statement even though field is an array
    def rights_list
      [
        {
          rights: source.dig('access', 'useAndReproductionStatement'),
          rights_uri: source.dig('access', 'license')
        }.compact_blank
      ]
    end

    # Our data collapses both funder name and award name into the "name" field
    # here, and it's not straightforward to separate, so we just keep the whole
    # thing as funder_name and ignore award_number.
    def funding_references
      return if (funders = all_contributors.filter(&:funder?)).blank?

      funders.map do |funder|
        funding_reference = { funder_name: funder[:name] }
        identifier = funder[:name_identifiers]&.first
        next funding_reference unless identifier

        funding_reference.merge(
          {
            funder_identifier: identifier[:name_identifier],
            funder_identifier_type: identifier[:name_identifier_scheme],
            scheme_uri: identifier[:scheme_uri]
          }.compact_blank
        )
      end
    end

    # We use the PURL as the canonical URL
    def url
      source.dig('description', 'purl')
    end

    # We only care about download access
    def access
      source.dig('access', 'download') == 'world' ? 'Public' : 'Restricted'
    end

    # Get the year values for all dates of a given type
    def date_years_by_type(type)
      all_dates.filter { |d| d.date_type == type }.map(&:year).compact
    end

    # Convert a Cocina relatedResource to DataCite structured data
    class RelatedItemMapper
      # Mapping of Cocina relatedResource types to DataCite relation types
      RELATION_TYPES = {
        'derived from' => 'IsDerivedFrom',
        'has other format' => 'isVariantFormOf',
        'preceded by' => 'IsNewVersionOf',
        'has original version' => 'IsNewVersionOf',
        'succeeded by' => 'IsPreviousVersionOf',
        'has version' => 'IsVersionOf',
        'has part' => 'HasPart',
        'is identical to' => 'IsIdenticalTo',
        'in series' => 'IsPartOf',
        'referenced by' => 'IsReferencedBy',
        'references' => 'References',
        'reviewed by' => 'IsReviewedBy',
        'source of' => 'IsSourceOf',
        'supplemented by' => 'IsSupplementedBy',
        'supplement to' => 'IsSupplementTo'
      }.freeze

      def initialize(resource)
        @resource = resource
      end

      # RelatedItem form; may not have an identifier or identifier may be a URL
      def call
        {
          titles:,
          relation_type:,
          related_item_identifier: {
            related_item_identifier: identifier.value || url,
            related_item_identifier_type: identifier.type || ('URL' if url)
          }
        }.compact_blank
      end

      # RelatedIdentifier form; must have an ID
      def as_related_identifier
        {
          relation_type:,
          related_identifier: identifier.value,
          related_identifier_type: identifier.type
        }.compact_blank
      end

      private

      attr_reader :resource

      def titles
        DataworksMappers::Sdr.map_titles(Array(resource['title']))
      end

      def identifier
        id = resource.dig('identifier', 0)
        IdentifierMapper.new(id) if id.present?
      end

      def url
        resource.dig('access', 'url', 0)
      end

      def relation_type
        RELATION_TYPES.fetch(resource['type'], 'Other')
      end
    end

    # Convert a Cocina event date to DataCite structured data
    class DateMapper
      # Mapping of Cocina event date types to DataCite date types
      DATE_TYPES = {
        'copyright' => 'Copyrighted',
        'collection' => 'Collected',
        'coverage' => 'Coverage',
        'creation' => 'Created',
        'production' => 'Created',
        'generation' => 'Created',
        'submission' => 'Submitted',
        'publication' => 'Issued',
        'release' => 'Issued',
        'distribution' => 'Issued',
        'modification' => 'Updated',
        'validity' => 'Valid',
        'withdrawal' => 'Withdrawn'
      }.freeze

      def initialize(date)
        @date = date
      end

      def call
        {
          date: date_value,
          date_type:,
          date_information:
        }.compact_blank
      end

      # Date type is required, so use 'Other' if not present or no mapping
      def date_type
        DATE_TYPES.fetch(date['type'], 'Other')
      end

      def year
        Date.edtf(date_value)&.year
      end

      private

      attr_reader :date

      # If the date is a range, return the start date
      def date_value
        date['value'] || date['structuredValue'].pick('value')
      end

      # Notes about the date, including original type if mapped to 'Other'
      def date_information
        notes = (date['note'] || []).pluck('value')
        notes.unshift(date['type']) if date_type == 'Other'
        notes.compact_blank.presence&.join('; ')
      end
    end

    # Convert a Cocina descriptive note to DataCite structured data
    class DescriptionMapper
      # Mapping of Cocina note types to DataCite description types
      DESCRIPTION_TYPES = {
        'abstract' => 'Abstract',
        'numbering' => 'SeriesInformation',
        'table of contents' => 'TableOfContents',
        'technical note' => 'TechnicalInfo'
      }.freeze

      def initialize(description)
        @description = description
      end

      def call
        return if description['value'].blank? || description_type.blank?

        {
          description: description['value'],
          description_type:
        }
      end

      private

      attr_reader :description

      def description_type
        DESCRIPTION_TYPES[description['type']]
      end
    end

    # Convert a Cocina identifier to DataCite structured data
    # NOTE: DataCite uses these frequently, but frustratingly the keys are named
    # differently depending on where it appears. Be careful!
    class IdentifierMapper
      # Scheme URI values for common identifiers
      SCHEME_URIS = {
        'ORCID' => 'https://orcid.org/',
        'ROR' => 'https://ror.org/',
        'DOI' => 'https://doi.org/',
        'ISNI' => 'https://isni.org/'
      }.freeze

      def initialize(identifier)
        @identifier = identifier
      end

      def value
        DataworksMappers::Sdr.id_from_url(identifier['value'])
      end

      def uri
        identifier['uri'] || [scheme_uri, value].compact.join
      end

      def type
        identifier['type'] || identifier.dig('source', 'code')
      end

      def scheme_uri
        identifier.dig('source', 'uri') || SCHEME_URIS[identifier['type']]
      end

      private

      attr_reader :identifier
    end

    # Convert a Cocina contributor to DataCite structured data
    class ContributorMapper
      # Cocina contributor roles (marcrelator codes) as DataCite contributor types
      CONTRIBUTOR_TYPES = {
        'mdc' => 'ContactPerson',
        'prc' => 'ContactPerson',
        'col' => 'DataCollector',
        'cur' => 'DataCurator',
        'dtm' => 'DataManager',
        'dst' => 'Distributor',
        'edt' => 'Editor',
        'his' => 'HostingInstitution',
        'pro' => 'Producer',
        'pdr' => 'ProjectLeader',
        'res' => 'Researcher',
        'oth' => 'Other',
        'cph' => 'RightsHolder',
        'spn' => 'Sponsor',
        'trl' => 'Translator'
      }.freeze

      # Generally we should be able to filter contributors using their marcrelator
      # role code, but some data doesn't use the code (even when it says it does),
      # so we have to check the role value instead.
      CREATOR_ROLES = ['author', 'authoring entity', 'primary investigator'].freeze

      def initialize(contributor)
        @contributor = contributor
      end

      def call
        {
          name:,
          name_type:,
          given_name:,
          family_name:,
          contributor_type:,
          affiliation:,
          name_identifiers:
        }.compact_blank
      end

      def creator?
        role_code == 'aut' || roles.any? { |r| CREATOR_ROLES.include? r.downcase }
      end

      def publisher?
        roles.any? { |r| r.downcase == 'publisher' }
      end

      def funder?
        roles.any? { |r| r.downcase == 'funder' }
      end

      private

      attr_reader :contributor

      def name
        contributor.dig('name', 0, 'value') || [given_name, family_name].compact.join(', ')
      end

      def name_type
        contributor['type'] == 'person' ? 'Personal' : 'Organizational'
      end

      def given_name
        contributor.dig('name', 0, 'structuredValue')&.filter { |v| v['type'] == 'forename' }&.pick('value')
      end

      def family_name
        contributor.dig('name', 0, 'structuredValue')&.filter { |v| v['type'] == 'surname' }&.pick('value')
      end

      def roles
        contributor['role']&.pluck('value') || []
      end

      def role_code
        contributor.dig('role', 0, 'code')
      end

      def contributor_type
        return if role_code.blank?
        return if creator? # Handled separately; doesn't get a type

        CONTRIBUTOR_TYPES.fetch(role_code, 'Other')
      end

      def affiliation
        return if (affiliation_notes = contributor['note']&.filter { |n| n['type'] == 'affiliation' }).blank?

        affiliation_notes.map { |note| AffiliationMapper.new(note).call }.compact
      end

      def name_identifiers
        return if (identifiers = contributor['identifier'].presence).blank?

        identifiers.map do |id|
          id_mapper = IdentifierMapper.new(id)

          {
            name_identifier: id_mapper.uri,
            name_identifier_scheme: id_mapper.type,
            scheme_uri: id_mapper.scheme_uri
          }.compact_blank
        end.compact
      end
    end

    # Convert a Cocina note with affiliation metadata to DataCite structured data
    class AffiliationMapper
      def initialize(affiliation)
        @affiliation = affiliation
      end

      def call
        {
          name: affiliation['value'],
          affiliation_identifier: identifier&.dig('identifier'),
          affiliation_identifier_scheme: identifier&.dig('scheme'),
          scheme_uri: identifier&.dig('scheme_uri')
        }.compact_blank
      end

      private

      attr_reader :affiliation

      def identifier
        IdentifierMapper.new(affiliation['identifier'].first).call if affiliation['identifier'].present?
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
