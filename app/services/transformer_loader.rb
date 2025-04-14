# frozen_string_literal: true

# Performs transformation from source metadata to Solr documents and loading into Solr
class TransformerLoader
  def self.call(...)
    new(...).call
  end

  def initialize(dataset_record_set:)
    @dataset_record_set = dataset_record_set
  end

  def call
    raise 'DatasetRecordSet is not complete' unless dataset_record_set.complete

    dataset_record_set.dataset_records.each do |dataset_record|
      solr_doc = solr_doc_for(dataset_record:)
      solr.add(solr_doc:)
    end
    solr.commit
  end

  private

  attr_reader :dataset_record_set

  def datacite_mapper
    @datacite_mapper ||= case dataset_record_set.provider
                         when 'redivis'
                           DataworksMappers::Redivis
                         when 'datacite'
                           DataworksMappers::Datacite
                         when 'dryad'
                           DataworksMappers::Dryad
                         when 'zenodo'
                           DataworksMappers::Zenodo
                         when 'local'
                           DataworksMappers::Local
                         else
                           raise "Unsupported provider: #{dataset_record_set.provider}"
                         end
  end

  def solr
    @solr ||= SolrService.new
  end

  def solr_doc_for(dataset_record:)
    metadata = datacite_mapper.call(source: dataset_record.source)
    SolrMapper.call(
      metadata:,
      dataset_record_id: dataset_record.id,
      dataset_record_set_id: dataset_record_set.id
    )
  end
end
