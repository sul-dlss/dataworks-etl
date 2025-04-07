# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Redivis do
  context 'when successful' do
    subject(:dataset_source_set) { described_class.call(organization: 'StanfordPHS') }

    let(:client) { instance_double(Clients::Redivis, list: results) }
    let(:results) do
      [
        Clients::ListResult.new(id: 'abc123', modified_token: 'v1'),
        Clients::ListResult.new(id: 'bcd456', modified_token: 'v2')
      ]
    end
    let!(:existing_dataset) { create(:dataset_source, dataset_id: 'bcd456') }
    let(:new_dataset_source) do
      {
        id: 'abc123',
        title: 'Test Dataset',
        doi: 'doi:10.0000/redivis.bcd456'
      }.stringify_keys
    end

    before do
      allow(Clients::Redivis).to receive(:new).and_return(client)
      allow(client).to receive(:dataset).and_return(new_dataset_source)
    end

    it 'creates a datasource set' do
      expect { dataset_source_set }
        .to change(DatasetSourceSet, :count).by(1)
        .and change(DatasetSource, :count).by(1)
      expect(Clients::Redivis).to have_received(:new).with(organization: 'StanfordPHS', api_token: String)
      expect(client).to have_received(:list)
      expect(client).to have_received(:dataset).with(id: 'abc123')
      expect(client).not_to have_received(:dataset).with(id: 'bcd456')

      new_source = DatasetSource.find_by!(dataset_id: 'abc123')
      expect(new_source.provider).to eq('redivis')
      expect(new_source.dataset_id).to eq('abc123')
      expect(new_source.modified_token).to eq('v1')
      expect(new_source.doi).to eq('doi:10.0000/redivis.bcd456')
      expect(new_source.source).to eq(new_dataset_source)
      expect(new_source.source_md5).to be_a(String)

      expect(dataset_source_set.provider).to eq('redivis')
      expect(dataset_source_set.complete).to be true
      expect(dataset_source_set.dataset_sources).to include(new_source)
      expect(dataset_source_set.dataset_sources).to include(existing_dataset)
    end
  end
end
