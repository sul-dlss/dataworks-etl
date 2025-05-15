# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetTransformerLoader do
  let(:redivis_dataset_record) { create(:dataset_record) }
  let(:datacite_dataset_record) { create(:dataset_record, :datacite) }

  let(:solr_service) { instance_double(SolrService, add: true) }
  let(:load_id) { 'abc123' }

  let(:provider_identifiers_map) do
    {
      'datacite' => datacite_dataset_record.dataset_id,
      'redivis' => redivis_dataset_record.dataset_id
    }
  end

  before do
    allow(SolrService).to receive(:new).and_return(solr_service)
    allow(DataworksMappers::Redivis).to receive(:call).and_call_original
    allow(DataworksMappers::Datacite).to receive(:call).and_call_original
    allow(SolrMapper).to receive(:call).and_call_original
  end

  it 'transforms and loads' do
    described_class.call(dataset_records: [redivis_dataset_record, datacite_dataset_record], load_id:)
    expect(DataworksMappers::Redivis).to have_received(:call).with(source: redivis_dataset_record.source).once
    expect(DataworksMappers::Datacite).to have_received(:call).with(source: datacite_dataset_record.source).once
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, doi: redivis_dataset_record.doi, id: redivis_dataset_record.doi,
            load_id:, provider_identifiers_map:).once
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, doi: datacite_dataset_record.doi, id: datacite_dataset_record.doi,
            load_id:, provider_identifiers_map:).once
    expect(solr_service).to have_received(:add).once do |args|
      solr_doc = args[:solr_doc]
      expect(solr_doc[:provider_ssi]).to eq('DataCite')
      # Merged in variables from redivis.
      expect(solr_doc[:variables_tsim]).to eq(['geometry'])
    end
  end

  context 'when there is an error in mapping' do
    before do
      allow(DataworksMappers::Datacite).to receive(:call).and_raise(DataworksMappers::MappingError)
    end

    it 'raises an error' do
      expect do
        described_class.call(dataset_records: [redivis_dataset_record, datacite_dataset_record], load_id:)
      end.to raise_error(DataworksMappers::MappingError)
      expect(SolrMapper).not_to have_received(:call)
    end
  end

  context 'when there is an error in mapping but dataset is ignored' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call)
        .with(source: redivis_dataset_record.source).and_raise(DataworksMappers::MappingError)
      allow(Settings.redivis).to receive(:ignore).and_return([redivis_dataset_record.dataset_id])
    end

    it 'ignores the error' do
      described_class.call(dataset_records: [redivis_dataset_record], load_id:)
      expect(solr_service).not_to have_received(:add)
    end
  end

  context 'when there is an ignored dataset that does not raise' do
    before do
      allow(Settings.redivis).to receive(:ignore).and_return([redivis_dataset_record.dataset_id])
      allow(Honeybadger).to receive(:notify)
    end

    it 'notifies Honeybadger' do
      described_class.call(dataset_records: [redivis_dataset_record, datacite_dataset_record], load_id:)
      expect(solr_service).to have_received(:add).once
      expect(Honeybadger).to have_received(:notify).with(/is ignored but mapping succeeded/)
    end
  end
end
