# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetTransformerLoader do
  let(:dataset_record) { create(:dataset_record) }

  let(:solr_service) { instance_double(SolrService, add: true) }
  let(:zenodo_dataset_record) { instance_double(DatasetRecord, provider: 'zenodo', dataset_id: 'zenodo-123') }
  let(:load_id) { 'abc123' }

  before do
    allow(SolrService).to receive(:new).and_return(solr_service)
    allow(DataworksMappers::Redivis).to receive(:call).and_call_original
    allow(SolrMapper).to receive(:call).and_call_original
  end

  it 'transforms and loads' do
    described_class.call(dataset_records: [zenodo_dataset_record, dataset_record], load_id:)
    expect(DataworksMappers::Redivis).to have_received(:call).with(source: dataset_record.source).once
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, doi: dataset_record.doi, id: dataset_record.doi, load_id:,
            provider_identifiers_map: { 'redivis' => 'abc1', 'zenodo' => 'zenodo-123' }).once
    expect(solr_service).to have_received(:add).once
  end

  context 'when there is an error in mapping' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call).and_raise(DataworksMappers::MappingError)
    end

    it 'raises an error' do
      expect do
        described_class.call(dataset_records: [zenodo_dataset_record, dataset_record], load_id:)
      end.to raise_error(DataworksMappers::MappingError)
      expect(SolrMapper).not_to have_received(:call)
    end
  end

  context 'when there is an error in mapping but dataset is ignored' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call)
        .with(source: dataset_record.source).and_raise(DataworksMappers::MappingError)
      allow(Settings.redivis).to receive(:ignore).and_return([dataset_record.dataset_id])
    end

    it 'ignores the error' do
      described_class.call(dataset_records: [zenodo_dataset_record, dataset_record], load_id:)
      expect(solr_service).not_to have_received(:add)
    end
  end

  context 'when there is an ignored dataset that does not raise' do
    before do
      allow(Settings.redivis).to receive(:ignore).and_return([dataset_record.dataset_id])
      allow(Honeybadger).to receive(:notify)
    end

    it 'notifies Honeybadger' do
      described_class.call(dataset_records: [zenodo_dataset_record, dataset_record], load_id:)
      expect(solr_service).to have_received(:add).once
      expect(Honeybadger).to have_received(:notify).with(/is ignored but mapping succeeded/)
    end
  end
end
