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
    DatasetRecordSet.select(:extractor, :list_args).group(:extractor, :list_args).pluck(:extractor, :list_args)
                    .filter_map do |extractor, list_args|
      DatasetRecordSet.latest_completed(extractor:, list_args:)
    end
  end

  def grouped_dataset_records
    dataset_records = DatasetRecord.joins(:dataset_record_associations)
                                   .where(dataset_record_associations: { dataset_record_set: dataset_record_sets })

    dataset_records.group_by(&:external_dataset_id)
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
    grouped_dataset_records.each_value do |dataset_records|
      solr_doc = DatasetTransformer.call(dataset_records:, load_id:, mapper_class:)
      solr_docs << solr_doc if solr_doc
    rescue DataworksMappers::MappingError
      raise if fail_fast?
    end
    # Remove previous or non-canonical versions
    consolidate_datasets(solr_docs)
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
  end
end
