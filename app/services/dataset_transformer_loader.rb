# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents and loading into Solr for a single dataset
class DatasetTransformerLoader
  # These providers are ordered by preference for mapping.
  PROVIDERS = %w[sdr datacite local searchworks dryad redivis zenodo].freeze

  # These fields are merged from the dataset records of other providers in preference order.
  MERGEABLE_FIELDS = [:variables_tsim].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(dataset_records:, load_id:, solr: SolrService.new)
    @dataset_records = dataset_records
    @solr = solr
    @load_id = load_id
  end

  def call
    solr_docs = dataset_records.filter_map { |dataset_record| solr_doc_for(dataset_record:) }
    solr_doc = solr_docs.shift
    # Merge in the fields that are mergeable from the other providers.
    solr_docs.each do |doc|
      solr_doc.reverse_merge!(doc.slice(*MERGEABLE_FIELDS))
    end
    solr.add(solr_doc:) if solr_doc
  end

  private

  attr_reader :solr, :load_id

  # @return [Array<DatasetRecord>] dataset records ordered by provider preference
  def dataset_records
    @dataset_records.sort_by do |dataset_record|
      PROVIDERS.index(dataset_record.provider)
    end
  end

  def mapper_for(dataset_record:)
    "DataworksMappers::#{dataset_record.provider.camelize}".constantize
  end

  def solr_doc_for(dataset_record:) # rubocop:disable Metrics/AbcSize
    Honeybadger.context(dataset_record_id: dataset_record.id, provider: dataset_record.provider,
                        dataset_id: dataset_record.dataset_id)
    metadata = mapper_for(dataset_record:).call(source: dataset_record.source)
    check_mapping_success(dataset_record:)

    SolrMapper.call(metadata:, doi: dataset_record.doi, id: dataset_record.external_dataset_id, load_id:,
                    provider_identifiers_map:)
  rescue DataworksMappers::MappingError => e
    return if ignore?(dataset_record:)

    Rails.logger.error "Mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
    Honeybadger.notify(e)
    raise
  end

  def ignore?(dataset_record:)
    ignore_dataset_ids(provider: dataset_record.provider).include?(dataset_record.dataset_id)
  end

  def ignore_dataset_ids(provider:)
    @ignore_dataset_ids ||= {}
    @ignore_dataset_ids[provider] ||= Settings[provider]&.ignore || []
    @ignore_dataset_ids[provider]
  end

  def check_mapping_success(dataset_record:)
    return unless ignore?(dataset_record:)

    msg = "Dataset #{dataset_record.dataset_id} (#{dataset_record.provider}) is ignored but mapping succeeded"
    Rails.logger.info(msg)
    Honeybadger.notify(msg)
  end

  def provider_identifiers_map
    dataset_records.to_h do |dataset_record|
      [dataset_record.provider, dataset_record.dataset_id]
    end
  end
end
