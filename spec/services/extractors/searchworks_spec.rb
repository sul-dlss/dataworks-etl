# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Searchworks do
  let(:example_doc) do
    {
      'id' => '123',
      'last_updated' => '2023-01-01T00:00:00Z',
      'url_fulltext' => ['http://doi.org/10.3886/ICPSR37620.v1'],
      'marc_json_struct' => [
        '{"fields":[{"700":{"subfields":[{"a":"Prysby, Charles"},{"u":"University of North Carolina-Greensboro"}]}}]}'
      ]
    }
  end

  let(:stanford_doc) do
    {
      'id' => '234',
      'last_updated' => '2023-01-01T00:00:00Z',
      'url_fulltext' => ['http://doi.org/10.3886/ICPSR37620.v2'],
      'marc_json_struct' => [
        '{"fields":[{"700":{"subfields":[{"a":"Prysby, Charles"},{"u":"Stanford University"}]}}]}'
      ]
    }
  end

  it 'merges default solr params with provided list args' do
    list_args = { params: { q: 'test' } }
    client = instance_double(Clients::Solr, list: [], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    params = extractor.send(:list_args)[:params]
    expect(params).to include(q: 'test')
    expect(params[:fl]).to include('title_display')
  end

  it 'maps solr docs into dataset records' do
    list_args = { params: { q: 'test' } }
    client = instance_double(Clients::Solr, list: [stanford_doc], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    extractor.call
    record = DatasetRecord.last
    expect(record.dataset_id).to eq('234')
    expect(record.modified_token).to eq('2023-01-01T00:00:00Z')
    expect(record.doi).to eq('10.3886/ICPSR37620.v2')
  end

  it 'retains only records that have Stanford affiliation' do
    list_args = { params: { q: 'test' } }
    client = instance_double(Clients::Solr, list: [example_doc, stanford_doc], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    extractor.call
    expect(DatasetRecord.where(dataset_id: '123')).not_to exist
    expect(DatasetRecord.where(dataset_id: '234')).to exist
  end
end
