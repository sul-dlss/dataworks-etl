# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::OpenAlex, :vcr do
  let(:client) { described_class.new }

  describe '.list' do
    context 'when passing an institution id' do
      let(:results) { client.list(institution_id:) }
      let(:institution_id) { 'I67328108' }

      it 'retrieves the list of datasets' do
        expect(results.size).to eq(5)
        result = results.first
        expect(result.id).to eq('https://openalex.org/W4398293344')
        expect(result.modified_token).to eq('2025-02-02T15:51:45.052029')
        expect(result.source).to be_a(Hash)
      end
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: 'https://openalex.org/W4398293344') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq('https://openalex.org/W4398293344')
      expect(dataset['title']).to eq('Replication Data for: The Aggregate Dynamics of Lower Court ' \
                                     'Responses to the US Supreme Court MKS_ReplicationCode_JLC.do')
    end
  end

  context 'when API token is provided' do
    let(:client) { described_class.new(api_token: 'test_api_token') }

    before do
      allow(client).to receive(:get_json).and_call_original
    end

    it 'includes the API token in the request' do
      client.list(institution_id: 'I67328108')
      expect(client).to have_received(:get_json)
        .with(hash_including(params: include(api_key: 'test_api_token'))).exactly(2).times
    end
  end

  describe '.dataset_doi' do
    let(:dataset) { client.dataset_doi(doi: '10.7910/dvn/qj9rlj') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq('https://openalex.org/W4398887383')
    end
  end

  describe '.query_relationship' do
    let(:results) { client.query_relationship(relationship: 'cites', id: 'W4398887383') }

    it 'retrieves the results' do
      expect(results.size).to eq(1)
      expect(results[0]['id']).to eq('https://openalex.org/W3171987103')
    end
  end
end
