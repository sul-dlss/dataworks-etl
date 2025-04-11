# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Searchworks do
  let(:example_marc) do
    {
      'fields' => [
        {
          '856' => {
            'subfields' => [
              { 'u' => 'http://doi.org/10.3886/ICPSR37620.v1' }
            ]
          }
        }
      ]
    }
  end

  let(:example_doc) do
    {
      'id' => '123',
      'last_updated' => '2023-01-01T00:00:00Z',
      'marc_json_struct' => example_marc.to_json
    }
  end

  it 'merges default solr params with provided list args' do
    list_args = { params: { q: 'test' } }
    client = instance_double(Clients::Solr, list: [], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    params = extractor.send(:list_args)[:params]
    expect(params).to include(q: 'test')
    expect(params).to include(fl: 'id,last_updated,marc_json_struct')
  end

  it 'maps solr docs into dataset records' do
    list_args = { params: { q: 'test' } }
    client = instance_double(Clients::Solr, list: [example_doc], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    extractor.call
    record = DatasetRecord.last
    expect(record.dataset_id).to eq('123')
    expect(record.modified_token).to eq('2023-01-01T00:00:00Z')
    expect(record.doi).to eq('http://doi.org/10.3886/ICPSR37620.v1')
    expect(record.source).to eq(example_marc)
  end

  context 'when there is no doi in the marc' do
    let(:example_marc) do
      {
        'fields' => [
          {
            '856' => {
              'subfields' => []
            }
          }
        ]
      }
    end

    it 'does not error and sets doi to nil' do
      list_args = { params: { q: 'test' } }
      client = instance_double(Clients::Solr, list: [example_doc], dataset: {})
      extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
      extractor.call
      record = DatasetRecord.last
      expect(record.doi).to be_nil
    end
  end

  context 'when there is an extra (hardcoded) dataset id' do
    it 'retrieves the extra dataset' do
      list_args = { params: { q: 'test' } }
      client = instance_double(Clients::Solr, list: [])
      extractor = described_class.new(list_args:, client:, extra_dataset_ids: ['123'])
      allow(client).to receive(:dataset).with(id: '123').and_return(example_doc)
      extractor.call
      record = DatasetRecord.last
      expect(record.dataset_id).to eq('123')
      expect(record.modified_token).to eq('2023-01-01T00:00:00Z')
      expect(record.doi).to eq('http://doi.org/10.3886/ICPSR37620.v1')
      expect(record.source).to eq(example_marc)
    end
  end
end
