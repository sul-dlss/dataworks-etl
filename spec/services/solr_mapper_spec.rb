# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrMapper do
  subject(:solr_mapper) { described_class.new(metadata:, dataset_record_id: 123, dataset_record_set_id: 456) }

  let(:metadata) do
    {
      titles: [{ title: 'PRIME India' }]
    }
  end

  describe '#call' do
    it 'maps to Solr metadata' do
      expect(solr_mapper.call).to eq(
        {
          id: 123,
          dataset_record_set_id: 456,
          title: 'PRIME India'
        }
      )
    end
  end
end
