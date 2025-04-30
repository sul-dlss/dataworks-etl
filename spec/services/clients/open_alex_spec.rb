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
      end
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: 'W4398293344') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq('https://openalex.org/W4398293344')
      expect(dataset['title']).to eq('Replication Data for: The Aggregate Dynamics of Lower Court ' \
                                     'Responses to the US Supreme Court MKS_ReplicationCode_JLC.do')
    end
  end
end
