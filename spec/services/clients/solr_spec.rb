# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Solr, :vcr do
  let(:client) { described_class.new }

  # NOTE: to record new VCR cassettes, you need to be able to access Solr without
  # authenticating. Here is one way:
  #
  # 1. `ssh -L 8983:sul-solr-prod-a:80 blacklight@sw-webapp-a` to tunnel to Solr
  # 2. modify the connection passed to the client to target localhost:8983
  # 3. set `c.ignore_localhost = false` in the VCR config in spec/rails_helper.rb
  # 4. run the test and record the cassette
  # 5. edit the cassette and change the URL to the production Solr URL
  # 6. disconnect from your ssh tunnel; revert spec/rails_helper.rb changes

  describe 'connection' do
    it 'does not use the Faraday json middleware' do
      expect(client.conn.builder.handlers).not_to include(Faraday::Response::Json)
    end

    it 'uses the FlatParamsEncoder' do
      expect(client.conn.options.params_encoder).to eq(Faraday::FlatParamsEncoder)
    end
  end

  describe '.list' do
    subject(:results) { client.list(params:, page_size:).to_a }

    let(:params) do
      {
        q: 'U.S. Customs and Border Protection. Air and Marine Operations,',
        search_field: 'search_author'
      }
    end
    let(:page_size) { 100 }

    it 'retrieves all matching datasets' do
      expect(results.length).to eq(14)
    end

    context 'when paginating' do
      let(:page_size) { 5 }

      it 'retrieves all matching datasets' do
        expect(results.length).to eq(14)
      end
    end

    context 'when there are no results' do
      let(:params) { { q: 'id:does_not_exist' } }

      it 'returns an empty array' do
        expect(results).to be_empty
      end
    end
  end

  describe '.dataset' do
    let(:dataset) { client.dataset(id: '13669313') }

    it 'retrieves the dataset' do
      expect(dataset['id']).to eq('13669313')
    end
  end
end
