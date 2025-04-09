# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Redivis, :vcr do
  let(:client) { described_class.new(api_token: Settings.redivis.api_token, organization: 'StanfordPHS') }

  describe '.list' do
    let(:results) { client.list(max_results: 50) }

    it 'retrieves the list of datasets' do
      expect(results.size).to eq(95)
      result = results.first
      expect(result.id).to eq('stanfordphs.prime_india:016c:v0_1')
      expect(result.modified_token).to eq('1582325197101')
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: 'stanfordphs.prime_india:016c:v0_1') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq('016c-aj7b81qhb')
    end
  end
end
