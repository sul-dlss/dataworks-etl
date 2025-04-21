# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Searchworks do
  let(:example_doc) do
    {
      'id' => '123',
      'last_updated' => '2023-01-01T00:00:00Z',
      'url_fulltext' => ['http://doi.org/10.3886/ICPSR37620.v1']
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
    client = instance_double(Clients::Solr, list: [example_doc], dataset: {})
    extractor = described_class.new(list_args:, client:, extra_dataset_ids: [])
    extractor.call
    record = DatasetRecord.last
    expect(record.dataset_id).to eq('123')
    expect(record.modified_token).to eq('2023-01-01T00:00:00Z')
    expect(record.doi).to eq('10.3886/ICPSR37620.v1')
  end
end
