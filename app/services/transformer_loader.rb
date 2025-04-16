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

    dataset_record_set.dataset_records.each do |dataset_record|
      solr_doc = solr_doc_for(dataset_record:)
      solr.add(solr_doc:) if solr_doc
    end
    solr.commit
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

  def solr_doc_for(dataset_record:)
    Honeybadger.context(dataset_record_id: dataset_record.id, provider: dataset_record.provider,
                        dataset_id: dataset_record.dataset_id)
    metadata = mapper.call(source: dataset_record.source)
    SolrMapper.call(
      metadata:,
      dataset_record_id: dataset_record.id,
      dataset_record_set_id: dataset_record_set.id
    )
  rescue DataworksMappers::MappingError => e
    raise if fail_fast

    Rails.logger.error "Mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
    Honeybadger.notify(e)
    nil
  end
end
