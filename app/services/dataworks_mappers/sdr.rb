# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module DataworksMappers
  # Map fields from SDR cocina records to Dataworks metadata
  class Sdr < Base
    class << self
      # Static helper to get a DOI that can be called from the indexer
      def doi(source:)
        CocinaDisplay::CocinaRecord.new(source).doi
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
        provider: 'SDR',
        stanford_project: true,
        access_contact:
      }.compact_blank
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    def titles
      TitleMapper.call(record)
    end

    # Druid is always present, but DOI may not be
    def identifiers
      [{ identifier: record.bare_druid, identifier_type: 'DRUID' }].tap do |ids|
        ids.push({ identifier: record.doi, identifier_type: 'DOI' }) if record.doi.present?
      end
    end

    def all_contributors
      record.contributors.map { |c| ContributorMapper.new(c) }
    end

    def creators
      all_contributors.filter(&:author?).map(&:call)
    end

    def contributors
      all_contributors.reject(&:author?).map(&:call)
    end

    # Use the publisher named in the record if present. SDR cocina metadata
    # usually does not carry publisher information, so we fall back to the
    # Stanford Digital Repository.
    def publisher
      all_contributors.find(&:publisher?)&.call || { name: 'Stanford Digital Repository' }
    end

    # If no publication year, fall back to year metadata was created
    def publication_year
      record.pub_year_int&.to_s || record.created_time.year.to_s
    end

    # We use whatever the first language in the record is (usually English)
    def language
      record.languages.filter_map(&:code).first
    end

    def subjects
      record.subject_topics.map { |topic| { subject: topic } }
    end

    def descriptions
      record.notes.map { |note| DescriptionMapper.new(note).call }.compact
    end

    def all_dates
      record.event_dates.map { |d| DateMapper.new(d) }
    end

    def dates
      all_dates.map(&:call).compact
    end

    # NOTE: This is the data version, not the (metadata) SDR version or user version
    def version
      record.path("$.description.note[?(@.type == 'version')].value").first
    end

    # Related items are used for things that may not have an identifier, often
    # user-provided links that only have a title and URL.
    def related_items
      record.related_resources.map { |r| RelatedItemMapper.new(r).call }.compact_blank
    end

    # Related resources with an identifier go here
    def related_identifiers
      record.related_resources.map { |r| RelatedItemMapper.new(r).as_related_identifier }.compact_blank
    end

    # Example data rarely had extents populated, so we fall back to total size
    def sizes
      record.extents.presence || [record.total_file_size_str]
    end

    # Example data rarely had forms populated, so we fall back to MIME types
    def formats
      record.forms.presence || record.file_mime_types
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
      all_contributors.filter(&:funder?).map(&:call).map do |funder|
        funding_reference = { funder_name: funder[:name] }
        identifier = funder[:name_identifiers]&.first
        next funding_reference unless identifier

        funding_reference.merge(
          {
            funder_identifier: identifier[:name_identifier],
            funder_identifier_type: identifier[:name_identifier_scheme]
          }.compact_blank
        )
      end.presence
    end

    # We use the PURL as the canonical URL
    def url
      record.purl_url
    end

    # We only care about download access
    def access
      source.dig('access', 'download') == 'world' ? 'Public' : 'Restricted'
    end

    # Get the year values for all dates of a given type
    def date_years_by_type(type)
      all_dates.filter { |d| d.date_type == type }.map(&:year).compact
    end

    # Get the access contact information
    def access_contact
      record.access_contacts.select(&:contact_email?).map do |access|
        { email: access.to_s }
      end
    end

    # Cached copy of the Cocina record object
    def record
      @record ||= CocinaDisplay::CocinaRecord.new(source)
    end

    # Convert Cocina titles to DataCite structured data
    class TitleMapper
      def self.call(record)
        [].tap do |titles|
          titles << { title: record.display_title } if record.display_title.present?
          record.additional_titles.each do |title|
            titles << { title: title, type: 'AlternativeTitle' }
          end
        end.compact
      end
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
            related_item_identifier: identifier&.identifier || resource.url,
            related_item_identifier_type: identifier&.type || ('URL' if resource.url?)
          }.compact_blank
        }.compact_blank
      end

      # RelatedIdentifier form; must have an ID
      def as_related_identifier
        return if identifier&.value.blank?

        {
          relation_type:,
          resource_type_general:,
          related_identifier: identifier.identifier,
          related_identifier_type: identifier.type
        }.compact_blank
      end

      private

      attr_reader :resource

      # RelatedResource#to_s will use titles if present, falling back to
      # preferred citation or other information as needed
      def titles
        [{ title: resource.to_s }]
      end

      def identifier
        resource.identifiers.first
      end

      # Items deposited using H3 may have dataCiteRelationType populated, but
      # if not, we need to convert using the lookup table
      def relation_type
        resource.cocina_doc.dig('description', 'dataCiteRelationType') || RELATION_TYPES.fetch(resource.type, nil)
      end

      # Items deposited using H3 may have DataCite resource type populated
      def resource_type_general
        resource.path(
          "$.description.form[?(@.type == 'resource type') && " \
          "(@.source.value == 'DataCite resource types')]"
        ).first
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
        return if formatted_value.blank?

        {
          date: formatted_value,
          date_type:,
          date_information:
        }.compact_blank
      end

      private

      attr_reader :date

      def formatted_value
        format_date(preferred_edtf_date) if preferred_edtf_date.present?
      end

      # Use only the value from the start if we have a range
      def preferred_edtf_date
        return date.start&.date if date.is_a?(CocinaDisplay::Dates::DateRange)

        date.date
      end

      # Date type is required, so use 'Other' if not present or no mapping
      def date_type
        DATE_TYPES.fetch(date.type, 'Other')
      end

      # Format the date like YYYY or YYYY-MM-DD based on precision
      def format_date(edtf_date)
        case edtf_date.precision
        when :year, :month
          edtf_date.strftime('%Y')
        when :day
          edtf_date.strftime('%Y-%m-%d')
        end
      end

      # Notes about the date, including original type if mapped to 'Other'
      # rubocop:disable Metrics/AbcSize
      def date_information
        notes = Array(date.cocina['note']).pluck('value')

        # The end date, if it was a range
        if date.is_a?(CocinaDisplay::Dates::DateRange) && date.stop&.date.present?
          notes.unshift("ended #{format_date(date.stop.date)}")
        end

        # The actual type, if it didn't fit datacite schema
        notes.unshift(date.type) if date_type == 'Other'

        # Join with semicolons
        notes.compact_blank.presence&.join('; ')
      end
      # rubocop:enable Metrics/AbcSize
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

      def initialize(note)
        @note = note
      end

      def call
        # If we didn't get a mappable type or no description, skip it
        return if description.blank? || description_type.blank?

        {
          description:,
          description_type:
        }
      end

      private

      attr_reader :note

      def description
        note.values.join("\n").strip
      end

      def description_type
        DESCRIPTION_TYPES[note.type]
      end
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
        'fnd' => 'Funder',
        'his' => 'HostingInstitution',
        'pro' => 'Producer',
        'pdr' => 'ProjectLeader',
        'res' => 'Researcher',
        'oth' => 'Other',
        'cph' => 'RightsHolder',
        'spn' => 'Sponsor',
        'trl' => 'Translator'
      }.freeze

      def initialize(contributor)
        @contributor = contributor
      end

      delegate :publisher?, :author?, :funder?, to: :contributor

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

      private

      attr_reader :contributor

      def name
        contributor.display_name
      end

      # All non-person types are mapped to 'Organizational'
      def name_type
        contributor.person? ? 'Personal' : 'Organizational'
      end

      def given_name
        contributor.forename
      end

      def family_name
        contributor.surname
      end

      # Uses the first role that maps to a known contributor type, falling back
      # to 'Other' since this property is required per DataCite
      def contributor_type
        return if author? # Handled separately; doesn't get a type

        contributor.roles.map { |role| CONTRIBUTOR_TYPES[role.code] }.compact.first || 'Other'
      end

      def affiliation
        contributor.affiliations.map do |affiliation|
          {
            name: affiliation.to_s,
            affiliation_identifier: affiliation.identifiers.first&.uri,
            affiliation_identifier_scheme: affiliation.identifiers.first&.type,
            scheme_uri: affiliation.identifiers.first&.scheme_uri
          }.compact_blank
        end.compact
      end

      def name_identifiers
        contributor.identifiers.map do |id|
          {
            name_identifier: id.uri,
            name_identifier_scheme: id.type,
            scheme_uri: id.scheme_uri
          }.compact_blank
        end.compact
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
