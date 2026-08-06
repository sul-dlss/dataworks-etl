# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Dataverse, :vcr do
  let(:client) { described_class.new(dataverse_token: Settings.dataverse.api_token) }

  describe '.dataset_doi' do
    let(:dataset) { client.dataset_doi(doi: '10.7910/dvn/reqh8f') }

    it 'retrieves the dataset' do
      expect(dataset['data']['persistentUrl']).to eq('https://doi.org/10.7910/DVN/REQH8F')
    end
  end
end
