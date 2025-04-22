# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransformerLoader do
  let(:dataset_record_set) { create(:dataset_record_set, :with_dataset_records, complete: true) }

  let(:dataset_record) { dataset_record_set.dataset_records.first }

  let(:solr_service) { instance_double(SolrService, add: true, commit: true) }

  before do
    allow(SolrService).to receive(:new).and_return(solr_service)
    allow(DataworksMappers::Redivis).to receive(:call).and_call_original
    allow(SolrMapper).to receive(:call).and_call_original
  end

  it 'transforms and loads' do
    described_class.call(dataset_record_set:)
    expect(DataworksMappers::Redivis).to have_received(:call).exactly(3).times
    expect(DataworksMappers::Redivis).to have_received(:call).with(source: dataset_record.source).once
    expect(SolrMapper).to have_received(:call).exactly(3).times
    expect(SolrMapper).to have_received(:call)
      .with(metadata: Hash, dataset_record_id: dataset_record.id,
            dataset_record_set_id: dataset_record_set.id).once
    expect(solr_service).to have_received(:add).exactly(3).times
    expect(solr_service).to have_received(:commit).once
  end

  context 'when the dataset record set is not complete' do
    let(:dataset_record_set) { create(:dataset_record_set, complete: false) }

    it 'raises an error' do
      expect { described_class.call(dataset_record_set:) }.to raise_error('DatasetRecordSet is not complete')
    end
  end

  context 'when unknown provider' do
    let(:dataset_record_set) { create(:dataset_record_set, :with_dataset_records, complete: true, provider: 'edivis') }

    it 'raises an error' do
      expect { described_class.call(dataset_record_set:) }.to raise_error('Unsupported provider: edivis')
    end
  end

  context 'when there is an error in mapping' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call).and_raise(DataworksMappers::MappingError)
    end

    it 'raises an error' do
      expect { described_class.call(dataset_record_set:) }.to raise_error(DataworksMappers::MappingError)
      expect(SolrMapper).not_to have_received(:call)
    end
  end

  context 'when there is an error in mapping and fail_fast is false' do
    before do
      allow(DataworksMappers::Redivis).to receive(:call).and_raise(DataworksMappers::MappingError)
      allow(Honeybadger).to receive(:notify)
    end

    it 'does not raise an error' do
      described_class.call(dataset_record_set:, fail_fast: false)
      expect(SolrMapper).not_to have_received(:call)
      expect(Honeybadger).to have_received(:notify).exactly(3).times
    end
  end
end
