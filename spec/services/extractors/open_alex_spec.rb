# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::OpenAlex do
  context 'when successful' do
    subject(:dataset_record_set) do
      described_class.call(institution_id: 'I97018004',
                           extra_dataset_ids: ['https://openalex.org/W4398575659'])
    end

    let(:client) { instance_double(Clients::OpenAlex, list: results) }
    let(:results) do
      [
        Clients::ListResult.new(id: 'https://openalex.org/W4398293344', modified_token: '2025-02-02T15:51:45.052029',
                                source: new_dataset_record_source),
        Clients::ListResult.new(id: 'https://openalex.org/W4398591158', modified_token: '2025-02-02T15:51:45.052029')
      ]
    end
    let!(:existing_dataset_record) do
      create(:dataset_record, dataset_id: 'https://openalex.org/W4398591158', provider: 'open_alex',
                              modified_token: '2025-02-02T15:51:45.052029')
    end
    let(:new_dataset_record_source) do
      {
        id: 'https://openalex.org/W4398293344',
        doi: 'https://doi.org/10.7910/dvn/dzzy7g/hzcqzp',
        title: 'Replication Data for: The Aggregate Dynamics of Lower Court Responses to the US Supreme Court',
        updated_date: '2025-02-02T15:51:45.052029'
      }.deep_stringify_keys
    end

    let(:extra_dataset_record_source) do
      {
        id: 'https://openalex.org/W4398575659',
        doi: 'https://doi.org/10.7910/dvn/pdi7in',
        title: '2016 United States Presidential Election Tweet Ids',
        updated_date: '2025-03-24T15:21:29.588202'
      }.deep_stringify_keys
    end

    before do
      allow(Clients::OpenAlex).to receive(:new).and_return(client)
      allow(client).to receive(:dataset).with(id: 'https://openalex.org/W4398575659')
                                        .and_return(extra_dataset_record_source)
    end

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(2)
      expect(Clients::OpenAlex).to have_received(:new)
      expect(client).to have_received(:list).with(institution_id: 'I97018004')
      expect(client).to have_received(:dataset).with(id: 'https://openalex.org/W4398575659')

      new_dataset_record = DatasetRecord.find_by!(dataset_id: 'https://openalex.org/W4398293344')
      expect(new_dataset_record.provider).to eq('open_alex')
      expect(new_dataset_record.modified_token).to eq('2025-02-02T15:51:45.052029')
      expect(new_dataset_record.doi).to eq('10.7910/dvn/dzzy7g/hzcqzp')
      expect(new_dataset_record.source).to eq(new_dataset_record_source)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('open_alex')
      expect(dataset_record_set.extractor).to eq('Extractors::OpenAlex')
      expect(dataset_record_set.list_args).to eq('{"institution_id":"I97018004"}')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
      expect(dataset_record_set.dataset_records).to include(existing_dataset_record)
    end
  end
end
