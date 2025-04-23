# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Sdr, :vcr do
  subject(:client) { described_class.new }

  describe '#list' do
    it 'fetches all the druids released to DataWorks' do
      results = client.list
      expect(results[0].id).to eq('druid:gh650rg1138')
      expect(results[0].modified_token).to eq('2025-01-10T18:06:48.000Z')
    end
  end

  describe '#dataset' do
    let(:druid) { 'zs631wn7371' }

    it 'fetches the Cocina model for the dataset' do
      dataset = client.dataset(id: druid)
      expect(dataset).to be_a(Cocina::Models::DROWithMetadata)
      expect(dataset.externalIdentifier).to eq("druid:#{druid}")
    end
  end
end
