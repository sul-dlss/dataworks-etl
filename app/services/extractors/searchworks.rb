# frozen_string_literal: true

module Extractors
  # Extractor for datasets in Searchworks's Solr index
  class Searchworks < Base
    def initialize(list_args:, client: Clients::Solr.new, provider: 'searchworks',
                   extra_dataset_ids: YAML.load_file('config/datasets/searchworks.yml'))
      super
      @list_args[:params].reverse_merge!(default_solr_params)
    end

    private

    def results
      Enumerator::Chain.new(
        extra_dataset_results,
        client.list(**list_args).map { |source| source_to_result(source:) }
      ).uniq(&:id)
    end

    # Client returns solr docs; we need to map them to ListResults
    def find_or_create_dataset_record(result:)
      super(result: source_to_result(source: result))
    end

    # Explicitly request the fields we use (and only those)
    def default_solr_params
      {
        # More things we could use, if needed:
        # * Extra URLs are sometimes in 'url_suppl'
        # * The MODS XML, if present, is in 'modsxml'
        # * The bare druid is in 'druid'
        fl: %w[
          id
          last_updated
          title_display
          pub_year_tisim
          production_year_isi
          copyright_year_isi
          language
          url_fulltext
          url_restricted
          summary_display
          topic_facet
          author_struct
          marc_json_struct
        ].join(',')
      }
    end

    # Map a Solr document into a ListResult
    def source_to_result(source:)
      return source if source.is_a?(Clients::ListResult)

      Clients::ListResult.new(
        id: source['id'],
        modified_token: source['last_updated'],
        source:
      )
    end

    # Delegate DOI extraction to the mapper since it's not trivial to extract
    def doi_from(source:)
      DataworksMappers::Searchworks.new(source:).doi_identifier&.[](:identifier)
    end
  end
end
