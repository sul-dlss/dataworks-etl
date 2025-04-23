# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::Base, :vcr do
  let(:url) { 'https://api.datacite.org' }
  let(:path) { '/dois/10.5061/dryad.rg148qj4' }

  describe '#get_json' do
    subject { described_class.new(url:) }

    let(:response) { subject.get_json(path:) }

    context 'when the request is successful' do
      it 'returns the parsed JSON response' do
        expect(response).to be_a(Hash)
      end
    end

    context 'when the request is not successful' do
      let(:path) { '/invalid_endpoint' }

      it 'raises an error' do
        expect { response }.to raise_error(Clients::Error)
      end
    end

    context 'when the JSON is invalid' do
      subject { described_class.new(conn: conn) }

      let(:conn) { instance_double(Faraday::Connection) }

      before do
        allow(conn).to receive(:get).and_raise(JSON::ParserError.new('Invalid JSON'))
      end

      it 'raises an error' do
        expect { response }.to raise_error(Clients::Error)
      end
    end

    context 'when there is a connection error' do
      subject { described_class.new(conn: conn) }

      let(:conn) { instance_double(Faraday::Connection) }

      before do
        allow(conn).to receive(:get).and_raise(Faraday::Error.new('Connection error'))
      end

      it 'raises an error' do
        expect { response }.to raise_error(Clients::Error)
      end
    end
  end
end
