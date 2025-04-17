# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Datacite do
  context 'when successful' do
    subject(:dataset_record_set) do
      described_class.call(affiliation: 'Stanford University', extra_dataset_ids: ['10.17632/7pxgdp7cn6'])
    end

    let(:client) { instance_double(Clients::Datacite, list: results) }
    let(:results) do
      [
        Clients::ListResult.new(id: '10.17632/8pxgdp7cn7', modified_token: 'v1'),
        Clients::ListResult.new(id: '10.17632/9pxgdp7cn9', modified_token: 'v2')
      ]
    end
    let!(:existing_dataset_record) { create(:dataset_record, dataset_id: '10.17632/9pxgdp7cn9', provider: 'datacite') }
    let(:new_dataset_record_source) do
      {
        data: {
          id: '10.17632/8pxgdp7cn7',
          type: 'dois'
        }
      }.deep_stringify_keys
    end

    let(:extra_dataset_record_source) do
      {
        data: {
          id: '10.17632/7pxgdp7cn6',
          type: 'dois',
          attributes: {
            doi: '10.17632/7pxgdp7cn6',
            version: '1'
          }
        }
      }.deep_stringify_keys
    end

    before do
      allow(Clients::Datacite).to receive(:new).and_return(client)
      allow(client).to receive(:dataset).with(id: '10.17632/8pxgdp7cn7').and_return(new_dataset_record_source)
      allow(client).to receive(:dataset).with(id: '10.17632/7pxgdp7cn6').and_return(extra_dataset_record_source)
    end

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(2)
      expect(Clients::Datacite).to have_received(:new)
      expect(client).to have_received(:list).with(affiliation: 'Stanford University', client_id: nil)
      expect(client).to have_received(:dataset).with(id: '10.17632/8pxgdp7cn7')
      expect(client).not_to have_received(:dataset).with(id: '10.17632/9pxgdp7cn9')

      new_dataset_record = DatasetRecord.find_by!(dataset_id: '10.17632/8pxgdp7cn7')
      expect(new_dataset_record.provider).to eq('datacite')
      expect(new_dataset_record.modified_token).to eq('v1')
      expect(new_dataset_record.doi).to eq('10.17632/8pxgdp7cn7')
      expect(new_dataset_record.source).to eq(new_dataset_record_source)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('datacite')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
      expect(dataset_record_set.dataset_records).to include(existing_dataset_record)
    end
  end
end
