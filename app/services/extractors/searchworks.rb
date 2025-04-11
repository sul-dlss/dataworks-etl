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

    # Solr doesn't return marc_json_struct by default, so we ask for it in order
    # to transform it in the mapper. We also need to ask for last_updated to
    # use as our modified_token.
    def default_solr_params
      {
        fl: 'id,last_updated,marc_json_struct'
      }
    end

    # Map a Solr document into a ListResult
    def source_to_result(source:)
      return source if source.is_a?(Clients::ListResult)

      Clients::ListResult.new(
        id: source['id'],
        modified_token: source['last_updated'],
        source: JSON.parse(source['marc_json_struct'])
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
