# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Sdr do
  let(:dataset) { JSON.parse(file_fixture('sdr.json').read) }
  let(:extractor) { described_class.new(client: client, extra_dataset_ids: []) }
  let(:client) { instance_double(Clients::Sdr, list: [list_result], dataset:) }
  let(:list_result) do
    Clients::ListResult.new(
      id: dataset['externalIdentifier'],
      modified_token: dataset['modified']
    )
  end

  context 'when DOI is stored as a descriptive identifier' do
    it 'extracts the DOI' do
      extractor.call
      record = DatasetRecord.last
      expect(record.doi).to eq('10.25740/ppax-bf07')
    end
  end

  context 'when the DOI is stored in the identification section' do
    before do
      dataset['identification']['doi'] = '10.25740/abc1234test'
      dataset['description'] = {}
    end

    it 'extracts the DOI' do
      extractor.call
      record = DatasetRecord.last
      expect(record.doi).to eq('10.25740/abc1234test')
    end
  end
end
