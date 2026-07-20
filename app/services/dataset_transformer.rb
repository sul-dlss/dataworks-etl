# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents for a single dataset
class DatasetTransformer
  # These providers are ordered by preference for mapping.
  PROVIDERS = %w[sdr datacite local searchworks dryad redivis zenodo].freeze

  # These fields are merged from the dataset records of other providers in preference order.
  MERGEABLE_FIELDS = [:variables_tsim].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(dataset_records:, load_id:, mapper_class: SolrMapper)
    @dataset_records = dataset_records
    @load_id = load_id
    @mapper_class = mapper_class
    # We will generate a hash of a list of suppression ids for each provider.
    # These ids require both reading from Settings and also other queries.
    @suppress_by_provider = extract_suppression_ids
  end

  # @return [Hash] Solr document for the dataset.
  def call
    solr_docs = dataset_records.filter_map { |dataset_record| solr_doc_for(dataset_record:) }
    solr_doc = solr_docs.shift
    # Merge in the fields that are mergeable from the other providers.
    solr_docs.each do |doc|
      solr_doc.reverse_merge!(doc.slice(*MERGEABLE_FIELDS))
    end

    # Apply additional metadata cleanup and return the solr document
    solr_doc.present? ? cleanup_metadata(solr_doc) : solr_doc
  end

  private

  attr_reader :load_id, :mapper_class

  # @return [Array<DatasetRecord>] dataset records ordered by provider preference
  def dataset_records
    @dataset_records.select { |dataset_record| PROVIDERS.include?(dataset_record.provider) }
                    .sort_by { |dataset_record| PROVIDERS.index(dataset_record.provider) }
                    .filter { |dataset_record| !suppress?(dataset_record:) }
  end

  def mapper_for(dataset_record:)
    "DataworksMappers::#{dataset_record.provider.camelize}".constantize
  end

  def solr_doc_for(dataset_record:) # rubocop:disable Metrics/AbcSize
    Honeybadger.context(dataset_record_id: dataset_record.id, provider: dataset_record.provider,
                        dataset_id: dataset_record.dataset_id)
    metadata = mapper_for(dataset_record:).call(source: dataset_record.source)

    # If item was on ignore list but metadata validation succeeds, notify
    check_mapping_success(dataset_record:)

    # Add enhancements
    metadata = enhance_metadata(mapped_record: metadata, doi: dataset_record.doi).with_indifferent_access

    # Call the Solr mapper (or vertex related transformation)
    mapper_class.call(metadata:, doi: dataset_record.doi, id: dataset_record.external_dataset_id, load_id:,
                      provider_identifiers_map:)
  rescue DataworksMappers::MappingError => e
    return if ignore?(dataset_record:)

    Rails.logger.error "Mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
    Honeybadger.notify(e)
    raise
  # This additional block allows for capturing other errors, such as malformed URIs
  # or exceptions that are not related to mapping. We want to raise an exception
  # only if they are not already on our ignore list, but flag them as a different
  # kind of error.
  rescue StandardError => e
    return if ignore?(dataset_record:)

    Rails.logger.error "Standard non-mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
    Honeybadger.notify(e)

    raise
  end

  def ignore?(dataset_record:)
    ignore_dataset_ids(provider: dataset_record.provider).include?(dataset_record.dataset_id)
  end

  def suppress?(dataset_record:)
    @suppress_by_provider[dataset_record.provider]&.include?(dataset_record.dataset_id)
  end

  # Ignored datasets are expected to raise mapping errors; if they do not,
  # we log and notify Honeybadger so they can be un-ignored as appropriate.
  def ignore_dataset_ids(provider:)
    @ignore_dataset_ids ||= {}
    @ignore_dataset_ids[provider] ||= Settings[provider]&.ignore || []
    @ignore_dataset_ids[provider]
  end

  # Suppressed datasets are always skipped without notification; they are used
  # for valid datasets that we nevertheless do not want to index.
  def extract_suppression_ids
    PROVIDERS.index_with { |provider| DatasetSuppressQuery.new(provider:).suppression_ids.compact }
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

  # Metadata standardization and cleanup
  def cleanup_metadata(solr_doc)
    MetadataCleaner.call(solr_doc:)
  end

  # Metadata enhancement one record at a time
  # Parameter is the DataWorks schema record, not Solr record
  def enhance_metadata(mapped_record:, doi:)
    MetadataEnhancer.call(mapped_record:, doi:)
  end
end
