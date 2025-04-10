# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Dryad do
  context 'when successful' do
    subject(:dataset_record_set) { described_class.call }

    let(:client) { instance_double(Clients::Dryad, list: results, dataset: new_dataset_record_source) }
    let(:results) do
      [
        Clients::ListResult.new(id: 'doi:10.5061/dryad.h18931zp7', modified_token: '1'),
        Clients::ListResult.new(id: 'doi:10.5061/dryad.hi18931zp8', modified_token: '2')
      ]
    end

    let!(:existing_dataset_record) do
      create(:dataset_record, dataset_id: 'doi:10.5061/dryad.hi18931zp8', provider: 'dryad')
    end
    let(:new_dataset_record_source) do
      {
        identifier: 'doi:10.5061/dryad.h18931zp7',
        id: 26_651,
        title: 'Data from: Data archiving is a good  investment'
      }.stringify_keys
    end

    before do
      allow(Clients::Dryad).to receive(:new).and_return(client)
    end

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(1)
      expect(Clients::Dryad).to have_received(:new)
      expect(client).to have_received(:list).with(affiliation: 'https://ror.org/00f54p054')
      expect(client).to have_received(:dataset).with(id: 'doi:10.5061/dryad.h18931zp7')
      expect(client).not_to have_received(:dataset).with(id: 'doi:10.5061/dryad.hi18931zp8')

      new_dataset_record = DatasetRecord.find_by!(dataset_id: 'doi:10.5061/dryad.h18931zp7')
      expect(new_dataset_record.provider).to eq('dryad')
      expect(new_dataset_record.modified_token).to eq('1')
      expect(new_dataset_record.doi).to eq('10.5061/dryad.h18931zp7')
      expect(new_dataset_record.source).to eq(new_dataset_record_source)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('dryad')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
      expect(dataset_record_set.dataset_records).to include(existing_dataset_record)
    end
  end
end
