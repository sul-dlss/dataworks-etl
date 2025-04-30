# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Redivis do
  context 'when successful' do
    subject(:dataset_record_set) { described_class.call(organization: 'StanfordPHS') }

    let(:client) { instance_double(Clients::Redivis, list: results, dataset: new_dataset_record_source) }
    let(:results) do
      [
        Clients::ListResult.new(id: 'abc123', modified_token: 'v1'),
        Clients::ListResult.new(id: 'bcd456', modified_token: 'v2')
      ]
    end
    let!(:existing_dataset_record) { create(:dataset_record, dataset_id: 'bcd456') }
    let(:new_dataset_record_source) do
      {
        id: 'abc123',
        title: 'Test Dataset',
        doi: 'doi:10.0000/redivis.bcd456'
      }.stringify_keys
    end

    before do
      allow(Clients::Redivis).to receive(:new).and_return(client)
    end

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(1)
      expect(Clients::Redivis).to have_received(:new).with(api_token: 'mytoken')
      expect(client).to have_received(:list).with(organization: 'StanfordPHS')
      expect(client).to have_received(:dataset).with(id: 'abc123')
      expect(client).not_to have_received(:dataset).with(id: 'bcd456')

      new_dataset_record = DatasetRecord.find_by!(dataset_id: 'abc123')
      expect(new_dataset_record.provider).to eq('redivis')
      expect(new_dataset_record.modified_token).to eq('v1')
      expect(new_dataset_record.doi).to eq('doi:10.0000/redivis.bcd456')
      expect(new_dataset_record.source).to eq(new_dataset_record_source)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('redivis')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
      expect(dataset_record_set.dataset_records).to include(existing_dataset_record)
    end
  end
end
