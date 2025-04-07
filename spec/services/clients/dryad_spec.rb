# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Dryad, :vcr do
  let(:client) { described_class.new }

  describe '.list' do
    let(:results) { client.list(affiliation: 'https://ror.org/028vqfs63', per_page: 15) }

    it 'retrieves the list of datasets' do
      expect(results.size).to eq(28)
      result = results.first
      expect(result.id).to eq('doi:10.5061/dryad.h18931zp7')
      expect(result.modified_token).to eq('2')
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: 'doi:10.5061/dryad.h18931zp7') }

    it 'retrieves the dataset' do
      expect(dataset['identifier']).to eq('doi:10.5061/dryad.h18931zp7')
    end
  end
end
