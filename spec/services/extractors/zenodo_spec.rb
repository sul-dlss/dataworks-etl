# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Zenodo do
  context 'when successful' do
    subject(:dataset_record_set) { described_class.call(extra_dataset_ids: ['3784817']) }

    let(:client) { instance_double(Clients::Zenodo, list: results) }
    let(:results) do
      [
        Clients::ListResult.new(id: '4999985', modified_token: '1'),
        Clients::ListResult.new(id: '4999986', modified_token: '2')
      ]
    end

    let!(:existing_dataset_record) do
      create(:dataset_record, dataset_id: '4999986', provider: 'zenodo', modified_token: '2')
    end

    let(:new_dataset_record_source) do
      {
        created: '2021-06-20T15:46:44.956104+00:00',
        modified: '2022-05-31T01:13:09.811588+00:00',
        id: 4_999_985,
        conceptrecid: '4999984',
        doi: '10.5061/dryad.st6h9',
        doi_url: 'https://doi.org/10.5061/dryad.st6h9'
      }.stringify_keys
    end

    let(:extra_dataset_record_source) do
      {
        created: '2020-05-04T13:53:31.638513+00:00',
        modified: '2020-05-04T20:20:25.287066+00:00',
        id: 3_784_817,
        conceptrecid: '597274',
        doi: '10.5281/zenodo.3784817',
        conceptdoi: '10.5281/zenodo.597274',
        doi_url: 'https://doi.org/10.5281/zenodo.3784817',
        revision: 3
      }.stringify_keys
    end

    before do
      allow(Clients::Zenodo).to receive(:new).and_return(client)
      allow(client).to receive(:dataset).with(id: '4999985').and_return(new_dataset_record_source)
      allow(client).to receive(:dataset).with(id: '3784817').and_return(extra_dataset_record_source)
    end

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(2)
      expect(Clients::Zenodo).to have_received(:new).with(api_token: 'myzenodotoken')
      expect(client).to have_received(:list).with(affiliation: 'Stanford University')
      expect(client).to have_received(:dataset).with(id: '4999985')
      expect(client).not_to have_received(:dataset).with(id: '4999986')

      new_dataset_record = DatasetRecord.find_by!(dataset_id: '4999985')
      expect(new_dataset_record.provider).to eq('zenodo')
      expect(new_dataset_record.modified_token).to eq('1')
      expect(new_dataset_record.doi).to eq('10.5061/dryad.st6h9')
      expect(new_dataset_record.source).to eq(new_dataset_record_source)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('zenodo')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
      expect(dataset_record_set.dataset_records).to include(existing_dataset_record)
    end
  end
end
