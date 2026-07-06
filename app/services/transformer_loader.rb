# frozen_string_literal: true

# Performs a transform and load of the most recent completed dataset record sets for each extractor / list arguments.
class TransformerLoader
  def self.call(**args, &)
    new(**args).call(&)
  end

  # @param fail_fast [Boolean] If true, raise an error on the first failure. If false, continue processing.
  # @param load [Boolean] If true, load the transformed documents into Solr. If false, only transform.
  def initialize(fail_fast: true, load_id: SecureRandom.uuid, load: true, mapper_class: SolrMapper)
    @fail_fast = fail_fast
    @load_id = load_id
    @load = load
    @mapper_class = mapper_class
  end

  def call(&)
    add_records(&)

    delete_records if load?
  end

  private

  attr_reader :load_id, :mapper_class

  def dataset_record_sets
    @dataset_record_sets ||= DatasetRecordSet.select(:extractor, :list_args).group(:extractor, :list_args).pluck(:extractor, :list_args)
                    .filter_map do |extractor, list_args|
      DatasetRecordSet.latest_completed(extractor:, list_args:)
    end
  end

  def solr
    @solr ||= SolrService.new
  end

  def load?
    @load
  end

  def fail_fast?
    @fail_fast
  end

  # Return array of solr docs to be added to the index
  def transform_records
    solr_docs = []

    # We are going to work through batches of grouped datasets so we don't
    # overwhelm memory
    # dataset_ids is of the form of [[]], where each row is [doi:, provider:, id:]
    list_dataset_ids.each_slice(100) do |dataset_ids|
      # Now run transform on this set of grouped records
      grouped_dataset_records(dataset_ids).each_value do |dataset_records|
        solr_doc = DatasetTransformer.call(dataset_records:, load_id:, mapper_class:)
        solr_docs << solr_doc if solr_doc
      rescue DataworksMappers::MappingError
        raise if fail_fast?
      end
    end

    # Remove previous or non-canonical versions
    consolidate_datasets(solr_docs)
  end

  # Create grouped records by id
  def grouped_dataset_records(dataset_ids)
    # First check by doi, then by provider and id combination
    # DOIs are frequent but not always present. We use provider + id combination to uniquely
    # identifiy a dataset. We have to account for both, especially as multiple providers
    # may have the same DOI.
    batch_records = (Array(lookup_dois(dataset_ids)) + Array(lookup_provider_id_combination(dataset_ids))).uniq(&:id)
    # Group by "external dataset id" which is doi OR provider-id
    batch_records.group_by(&:external_dataset_id)
  end

  # In order not to keep everything in memory as we process the records,
  # we will first retrieve all the unique external ids we will group by
  def list_dataset_ids
    DatasetRecord.joins(:dataset_record_associations)
                 .where(dataset_record_associations: { dataset_record_set: dataset_record_sets })
                 .order(:doi)
                 .pluck(:doi, :provider, :dataset_id)
                 .uniq { |doi, provider, dataset_id| doi || "#{provider}-#{dataset_id}"}
  end

  # Look up all dois
  # Input = { :doi, :provider, :dataset_id}
  def lookup_dois(dataset_ids)
    dois = dataset_ids.pluck(0).compact.uniq

    if dois.any?
      DatasetRecord.joins(:dataset_record_associations)
                   .where(dataset_record_associations: { dataset_record_set: dataset_record_sets })
                   .where(doi: dois)
                   .includes(:dataset_record_associations)
    else
      []
    end
  end

  def lookup_provider_id_combination(dataset_ids)
    # Create pairs for each provider, id combination
    provider_id_pairs = dataset_ids.map { |row| [row[1], row[2]] }.uniq

    if provider_id_pairs.any?
      DatasetRecord.joins(:dataset_record_associations)
                   .where(dataset_record_associations: { dataset_record_set: dataset_record_sets })
                   .where(%i[provider dataset_id] => provider_id_pairs)
                   .includes(:dataset_record_associations)
    else
      []
    end
  end

  # Given an array of solr docs, review which dois appear to be versions of the same
  # id and keep only the most recent or canonical versions.
  # Also remove any parts of datasets where we have the datasets themselves
  def consolidate_datasets(solr_docs)
    dois_to_remove = DatasetConsolidator.new(solr_docs:).removal_dois_set
    # Return Solr docs without the DOIs to remove
    solr_docs.reject { |solr_doc| dois_to_remove.include?(solr_doc['doi_ssi']) }
  end

  def add_records
    solr_docs = transform_records
    solr_docs.each do |solr_doc|
      solr.add(solr_doc:) if load?
      yield solr_doc if block_given?
    end
  rescue DataworksMappers::MappingError
    raise if fail_fast?
  ensure
    solr.commit if load?
  end

  def delete_records
    solr.delete_by_query(query: "-load_id_ssi:\"#{load_id}\"")
    solr.commit
  end
end
