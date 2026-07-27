# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataverseEnhancer do
  let(:dataverse_client) { instance_double(Clients::Dataverse) }
  let(:mapped_record) { { 'url' => 'https://dataverse.harvard.edu/citation?persistentId=doi:10.7910/DVN/REQH8F' } }
  let(:dataverse_dataset) { JSON.parse(File.read('spec/fixtures/sources/dataverse.json')) }
  let(:enhanced_record) { described_class.new(mapped_record:, doi: '10.7910/DVN/REQH8F').add_metadata }


  before do
    allow(Clients::Dataverse).to receive(:new).and_return(dataverse_client)
    allow(dataverse_client).to receive_messages(dataset_doi: dataverse_dataset)
  end

  context 'when the original metadata has no related publications' do
    it 'adds publications from Dataverse' do
      expect(enhanced_record['related_identifiers']).to include(hash_including('related_identifier' => 'www.pnas.org/cgi/doi/10.1073/pnas.1915460117',
                                                                               'related_identifier_type' => 'DOI',
                                                                               'relation_type' => 'IsCitedBy'))
    end
  end
end
