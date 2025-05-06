# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Datacite, :vcr do
  let(:client) { described_class.new }

  describe '.list' do
    context 'when passing an affiliation' do
      let(:results) { client.list(affiliation: 'Amherst College', page_size: 100) }

      it 'retrieves the list of datasets' do
        expect(results.size).to eq(137)
        result = results.first
        expect(result.id).to eq('10.5061/dryad.rg148qj4')
        expect(result.modified_token).to eq('2025-03-01T02:19:51Z')
      end
    end

    context 'when passing a client_id' do
      let(:results) { client.list(client_id: 'sul.openneuro', page_size: 100) }

      it 'retrieves the list of datasets' do
        expect(results.size).to eq(4385)
        result = results.first
        expect(result.id).to eq('10.18112/p2159b')
        expect(result.modified_token).to eq('2020-08-19T21:04:58Z')
      end
    end

    context 'when passing a provider_id' do
      let(:results) { client.list(provider_id: 'sul') }

      it 'retrieves the list of datasets' do
        expect(results.size).to eq(5804)
        result = results.first
        expect(result.id).to eq('10.18112/p2159b')
        expect(result.modified_token).to eq('2020-08-19T21:04:58Z')
      end
    end

    context 'when passing no query parameters' do
      it 'raises an error' do
        expect { client.list }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: '10.5061/dryad.rg148qj4') }

    it 'retrieves the dataset' do
      expect(dataset['data']['id']).to eq('10.5061/dryad.rg148qj4')
    end
  end
end
