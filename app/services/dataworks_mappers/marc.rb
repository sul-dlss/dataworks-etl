# frozen_string_literal: true

module DataworksMappers
  # Map from MARC records to Dataworks metadata
  class Marc < Base
    def initialize(source:, provider:)
      super(source:)
      @provider = provider
      @record = MARC::Record.new_from_hash(source)
    end

    private

    attr_reader :record, :provider

    def perform_map
      {
        identifiers:,
        creators:,
        titles:,
        publication_year:,
        subjects:,
        provider:,
        descriptions:,
        url: doi_url,
        access:
      }.compact_blank
    end

    def identifiers
      [searchworks_identifier, doi_identifier].compact
    end

    def searchworks_identifier
      { identifier: record['001'].value, identifier_type: 'searchworks_reference' }
    end

    # Just the identifier part, e.g. 10.1234/5678
    def doi_identifier
      return unless doi_url

      { identifier: URI(doi_url).path.delete_prefix('/'), identifier_type: 'DOI' }
    end

    def doi_url
      record['856']['u']
    end

    def titles
      [
        { title: record['245']['a'] } # no type specified = main title
      ]
    end

    def descriptions
      [
        { description: record['520']['a'], description_type: 'Abstract' }
      ]
    end

    def publisher
      record['264']['b'] || record['786']['n']
    end

    def publication_year
      record['264']['c']
    end

    def subjects
      record['650'].map do |subject|
        {
          subject: subject['a'],
          subject_scheme: 'Library of Congress Subject Headings (LCSH)'
        }
      end
    end
  end
end
