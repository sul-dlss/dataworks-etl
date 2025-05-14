# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Redivis, :vcr do
  let(:client) { described_class.new(api_token: Settings.redivis.api_token) }

  describe '.list' do
    let(:results) { client.list(organization: 'StanfordPHS', max_results: 50) }

    it 'retrieves the list of datasets' do
      expect(results.size).to eq(95)
      result = results.first
      expect(result.id).to eq('stanfordphs.prime_india:016c:v0_1')
      expect(result.modified_token).to eq('1582325197101')
    end
  end

  describe '.dataset' do
    context 'when there are no tables' do
      let(:dataset) { client.dataset(id: 'stanfordphs.prime_india:016c:v0_1') }

      it 'retrieves the dataset' do
        expect(dataset['id']).to eq('016c-aj7b81qhb')
        expect(dataset['tableCount']).to eq(0)
        expect(dataset['tables']).to be_nil
      end
    end

    context 'when there are tables' do
      let(:dataset) { client.dataset(id: 'sdss.project_loon:673p:v1_0') }

      it 'retrieves the dataset' do
        expect(dataset['id']).to eq('673p-a2f2hqe7m')
        expect(dataset['tableCount']).to eq(1)
        expect(dataset['tables'].size).to eq(1)
        table = dataset['tables'].first
        expect(table['variableCount']).to eq(30)
        expect(table['variables'].size).to eq(30)
        expect(table['variables'].first['name']).to eq('flight_id')
      end
    end
  end
end
