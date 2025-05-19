# frozen_string_literal: true

# Performs a transform and load of the most recent completed dataset record sets for each extractor / list arguments.
class TransformerLoader
  def self.call(**args, &)
    new(**args).call(&)
  end

  # @param fail_fast [Boolean] If true, raise an error on the first failure. If false, continue processing.
  # @param load [Boolean] If true, load the transformed documents into Solr. If false, only transform.
  def initialize(fail_fast: true, load_id: SecureRandom.uuid, load: true)
    @fail_fast = fail_fast
    @load_id = load_id
    @load = load
  end

  def call(&)
    add_records(&)

    delete_records if load?
  end

  private

  attr_reader :load_id

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

  def add_records # rubocop:disable Metrics/CyclomaticComplexity
    grouped_dataset_records.each_value do |dataset_records|
      solr_doc = DatasetTransformer.call(dataset_records:, load_id:)
      next unless solr_doc

      solr.add(solr_doc:) if load?
      yield solr_doc if block_given?
    rescue DataworksMappers::MappingError
      raise if fail_fast?
    end
  ensure
    solr.commit if load?
  end

  def delete_records
    solr.delete_by_query(query: "-load_id_ssi:\"#{load_id}\"")
  end
end
