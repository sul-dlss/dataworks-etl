# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetTransformer do
  subject(:solr_doc) do
    described_class.call(dataset_records:, load_id:, suppress_by_provider:)
  end

  let(:suppress_by_provider) do
    DatasetSuppressQuery.suppression_ids_by_provider(providers: DatasetTransformer::PROVIDERS)
  end

  let(:openalex_client) { instance_double(Clients::OpenAlex) }
  let(:dataset_records) { [redivis_dataset_record, datacite_dataset_record] }
  let(:redivis_dataset_record) { create(:dataset_record) }
  let(:datacite_dataset_record) { create(:dataset_record, :datacite) }
  let(:datacite_dataset_publisher_record) { create(:dataset_record, :datacite_with_publisher) }

  let(:load_id) { 'abc123' }

  let(:provider_identifiers_map) do
    {
      'datacite' => datacite_dataset_record.dataset_id,
      'redivis' => redivis_dataset_record.dataset_id
    }
  end

  before do
    allow(DataworksMappers::Redivis).to receive(:call).and_call_original
    allow(DataworksMappers::Datacite).to receive(:call).and_call_original
    allow(SolrMapper).to receive(:call).and_call_original
    allow(Clients::OpenAlex).to receive(:new).and_return(openalex_client)
    allow(openalex_client).to receive(:dataset_doi).and_return({})
  end

  it 'transforms' do
    expect(solr_doc[:provider_ssi]).to eq('DataCite')
    # Merged in variables from redivis.
    expect(solr_doc[:variables_tsim]).to eq(['geometry'])

    expect(DataworksMappers::Redivis).to have_received(:call).with(source: redivis_dataset_record.source).once
    expect(DataworksMappers::Datacite).to have_received(:call).with(source: datacite_dataset_record.source).once
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, doi: redivis_dataset_record.doi, id: redivis_dataset_record.doi,
            load_id:, provider_identifiers_map:).once
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, doi: datacite_dataset_record.doi, id: datacite_dataset_record.doi,
            load_id:, provider_identifiers_map:).once
  end

  context 'when there is an error in mapping' do
    before do
      allow(DataworksMappers::Datacite).to receive(:call).and_raise(DataworksMappers::MappingError)
    end

    it 'raises an error' do
      expect { solr_doc }.to raise_error(DataworksMappers::MappingError)
    end
  end

  context 'when there is an error in mapping but dataset is ignored' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call)
        .with(source: redivis_dataset_record.source).and_raise(DataworksMappers::MappingError)
      allow(Settings.redivis).to receive(:ignore).and_return([redivis_dataset_record.dataset_id])
    end

    let(:dataset_records) { [redivis_dataset_record] }

    it 'ignores the error' do
      expect(solr_doc).to be_nil
    end
  end

  context 'when there is an ignored dataset that does not raise' do
    before do
      allow(Settings.redivis).to receive(:ignore).and_return([redivis_dataset_record.dataset_id])
      allow(Honeybadger).to receive(:notify)
    end

    it 'notifies Honeybadger' do
      expect(solr_doc).to be_a(Hash)
      expect(Honeybadger).to have_received(:notify).with(/is ignored but mapping succeeded/)
    end
  end

  context 'when there is a suppressed dataset' do
    before do
      allow(Settings.redivis).to receive(:suppress).and_return([redivis_dataset_record.dataset_id])
      allow(Honeybadger).to receive(:notify)
    end

    let(:dataset_records) { [redivis_dataset_record] }

    it 'skips the dataset without notifying Honeybadger' do
      expect(solr_doc).to be_nil
      expect(Honeybadger).not_to have_received(:notify)
    end
  end

  context 'when there is a suppressed dataset based on suppression query' do
    before do
      allow(Settings.datacite).to receive(:suppress).and_return([])
      allow(Honeybadger).to receive(:notify)
    end

    let(:dataset_records) { [datacite_dataset_publisher_record] }

    it 'skips the dataset without notifying Honeybadger' do
      expect(solr_doc).to be_nil
      expect(Honeybadger).not_to have_received(:notify)
    end
  end
end
