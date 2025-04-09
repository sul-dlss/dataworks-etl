# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Zenodo, :vcr do
  let(:client) { described_class.new(api_token: Settings.zenodo.api_token) }

  describe '.list' do
    let(:results) { client.list(affiliation: 'Amherst College', page_size: 25) }

    it 'retrieves the list of datasets' do
      expect(results.size).to eq(42)
      result = results.first
      expect(result.id).to eq('4999985')
      expect(result.modified_token).to eq('3')
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: '4999985') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq(4_999_985)
    end
  end
end
