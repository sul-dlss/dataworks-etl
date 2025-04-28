# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents and loading into Solr
class TransformerLoader
  def self.call(...)
    new(...).call
  end

  def initialize(dataset_record_set:, fail_fast: true)
    @dataset_record_set = dataset_record_set
    @fail_fast = fail_fast
  end

  def call
    raise 'DatasetRecordSet is not complete' unless dataset_record_set.complete

    add_solr_docs
    delete_solr_docs
  end

  private

  attr_reader :dataset_record_set, :fail_fast

  # rubocop:disable Metrics/CyclomaticComplexity
  def mapper
    @mapper ||= case dataset_record_set.provider
                when 'redivis'
                  DataworksMappers::Redivis
                when 'datacite'
                  DataworksMappers::Datacite
                when 'dryad'
                  DataworksMappers::Dryad
                when 'searchworks'
                  DataworksMappers::Searchworks
                when 'zenodo'
                  DataworksMappers::Zenodo
                when 'local'
                  DataworksMappers::Local
                else
                  raise "Unsupported provider: #{dataset_record_set.provider}"
                end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def solr
    @solr ||= SolrService.new
  end

  def solr_doc_for(dataset_record:) # rubocop:disable Metrics/AbcSize
    Honeybadger.context(dataset_record_id: dataset_record.id, provider: dataset_record.provider,
                        dataset_id: dataset_record.dataset_id)
    metadata = mapper.call(source: dataset_record.source)
    check_mapping_success(dataset_record:)

    SolrMapper.call(metadata:, dataset_record_id: dataset_record.id, dataset_record_set_id: dataset_record_set.id)
  rescue DataworksMappers::MappingError => e
    return if ignore?(dataset_record:)

    raise if fail_fast

    Rails.logger.error "Mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
    Honeybadger.notify(e)
    nil
  end

  def ignore?(dataset_record:)
    ignore_dataset_ids.include?(dataset_record.dataset_id)
  end

  def ignore_dataset_ids
    @ignore_dataset_ids ||= Settings[dataset_record_set.provider]&.ignore || []
  end

  def check_mapping_success(dataset_record:)
    return unless ignore?(dataset_record:)

    msg = "Dataset #{dataset_record.dataset_id} (#{dataset_record.provider}) is ignored but mapping succeeded"
    Rails.logger.info(msg)
    Honeybadger.notify(msg)
  end

  def add_solr_docs
    dataset_record_set.dataset_records.each do |dataset_record|
      solr_doc = solr_doc_for(dataset_record:)
      solr.add(solr_doc:) if solr_doc
    end
    solr.commit
  end

  def delete_solr_docs
    outdated_dataset_record_ids = previous_dataset_record_ids - dataset_record_set.dataset_records.ids
    return if outdated_dataset_record_ids.blank?

    outdated_dataset_record_ids.each { |id| solr.delete(id:) }
    solr.commit
  end

  def previous_dataset_record_ids
    @previous_dataset_record_ids ||= begin
      dataset_record_sets = DatasetRecordSet.where(extractor: dataset_record_set.extractor,
                                                   list_args: dataset_record_set.list_args)
                                            .where.not(id: dataset_record_set.id)
      DatasetRecord.joins(:dataset_record_associations)
                   .where(dataset_record_associations: { dataset_record_set: dataset_record_sets })
                   .distinct.ids
    end
  end
end
