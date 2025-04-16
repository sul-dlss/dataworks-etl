# frozen_string_literal: true

module Extractors
  # Extractor for datasets in Searchworks's Solr index
  class Searchworks < Base
    def initialize(list_args:, client: Clients::Solr.new, provider: 'searchworks',
                   extra_dataset_ids: YAML.load_file('config/datasets/searchworks.yml'))
      super
      @list_args[:params].merge!(default_solr_params)
    end

    private

    # Client returns solr docs; we need to map them to ListResults
    def find_or_create_dataset_record(result:)
      super(result: source_to_result(source: result))
    end

    # Explicitly request the fields we use (and only those)
    def default_solr_params
      {
        fl: %w[
          id
          last_updated
          title_display
          title_245c_display
          publication_year_isi
          url_fulltext
          url_restricted
          summary_display
          author_person_facet
          author_other_facet
          topic_facet
          author_struct
          marc_links_struct
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

    # Use the first 856$u we find as the DOI
    def doi_from(source:)
      source['fields'].filter_map { |f| f['856'] if f.key? '856' }
                      .flat_map { |f| f['subfields'] }
                      .filter { |f| f.key? 'u' }
                      .pick('u')
    end
  end
end
