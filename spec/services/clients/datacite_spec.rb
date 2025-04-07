# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Datacite, :vcr do
  let(:client) { described_class.new }

  describe '.list' do
    let(:results) { client.list(affiliation: 'Amherst College', page_size: 100) }

    it 'retrieves the list of datasets' do
      expect(results.size).to eq(137)
      result = results.first
      expect(result.id).to eq('10.5061/dryad.rg148qj4')
      expect(result.modified_token).to eq('2025-03-01T02:19:51Z')
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: '10.5061/dryad.rg148qj4') }

    it 'retrieves the dataset' do
      expect(dataset['data']['id']).to eq('10.5061/dryad.rg148qj4')
    end
  end
end
