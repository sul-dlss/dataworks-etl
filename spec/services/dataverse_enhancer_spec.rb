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

  context 'when the original metadata has no related publications but Dataverse returns related publications' do
    it 'adds publications from Dataverse' do
      # Based on dataverse.json fixture, we should get back four items with various fields present
      # We should not get back the fifth item that has no ID attached
      # First case: mapping from doi and number, using default relationship
      # Second case: mapping using ISBN as type, using default relationshp
      # Third case: A DOI where only the number was provided without ID type or relationship
      # Fourth case:  A DOI where a relationship type is provided aong with ID type
      # Fifth case (which should be returned): Some info but no identifier number
      expected_publications = [
        { 'related_identifier' => 'www.pnas.org/cgi/doi/10.1073/pnas.1915460117',
          'related_identifier_type' => 'DOI',
          'relation_type' => 'IsCitedBy' },
        { 'related_identifier' => 'testISBN',
          'related_identifier_type' => 'ISBN',
          'relation_type' => 'IsCitedBy' },
        { 'related_identifier' => '10.111.1345/testdoi',
          'relation_type' => 'IsCitedBy' },
        { 'related_identifier' => '10.1073/123/123',
          'related_identifier_type' => 'DOI',
          'relation_type' => 'References' }
      ]

      expect(enhanced_record['related_identifiers']).to match(a_collection_containing_exactly(*expected_publications))
    end
  end

  context 'when the Dataverse client errors while enhancing' do
    before do
      allow(dataverse_client).to receive(:dataset_doi).and_raise(Clients::Error)
      allow(Honeybadger).to receive(:notify)
    end

    it 'returns the original metadata record so the transform can continue' do
      expect(enhanced_record).to eq(mapped_record)
    end
  end

  context 'when the metadata record already has related identifiers with no overlapping dois' do
    let(:mapped_record) do
      { 'url' => 'https://dataverse.harvard.edu/citation?persistentId=doi:10.7910/DVN/REQH8F',
        'related_identifiers' => [{ 'related_identifier' => 'https://testid' }] }
    end

    it 'retains the original related identifiers and adds the new ones from Dataverse' do
      expect(enhanced_record['related_identifiers'].size).to eq(5)
    end
  end

  context 'when the metadata record has related identifiers with an overlapping doi' do
    # The existing record has a DOI without any relation type, whereas Dataverse
    # gives us a relationship type. Since we already have this DOI in our
    # existing set of related identifiers, we will not be copying over the new info.
    let(:mapped_record) do
      { 'url' => 'https://dataverse.harvard.edu/citation?persistentId=doi:10.7910/DVN/REQH8F',
        'related_identifiers' => [{
          'related_identifier' => '10.1073/123/123',
          'related_identifier_type' => 'DOI'
        }] }
    end

    let(:from_dataverse) do
      {
        'related_identifier' => '10.1073/123/123',
        'related_identifier_type' => 'DOI',
        'relation_type' => 'References'
      }
    end

    it 'does not add the Dataverse info' do
      expect(enhanced_record['related_identifiers'].size).to eq(4)
      expect(enhanced_record['related_identifiers']).not_to include(hash_including(from_dataverse))
      expect(enhanced_record['related_identifiers']).to include(mapped_record['related_identifiers'].first)
    end
  end

  context 'when the metadata record has related identifiers with an overlapping doi with different case' do
    # The existing record has a DOI without any relation type, whereas Dataverse
    # gives us a relationship type. Since we already have this DOI in our
    # existing set of related identifiers, we will not be copying over the new info.
    let(:mapped_record) do
      { 'url' => 'https://dataverse.harvard.edu/citation?persistentId=doi:10.7910/DVN/REQH8F',
        'related_identifiers' => [{
          'related_identifier' => '10.111.1345/TestDOI'
        }] }
    end

    let(:from_dataverse) do
      {
        'related_identifier' => '10.111.1345/testdoi'
      }
    end

    it 'does not add the Dataverse info' do
      expect(enhanced_record['related_identifiers'].size).to eq(4)
      expect(enhanced_record['related_identifiers']).not_to include(hash_including(from_dataverse))
      expect(enhanced_record['related_identifiers']).to include(mapped_record['related_identifiers'].first)
    end
  end
end
