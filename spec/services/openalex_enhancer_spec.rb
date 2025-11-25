# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenalexEnhancer do
  let(:openalex_client) { instance_double(Clients::OpenAlex) }
  let(:openalex_dataset) do
    {
      'id' => 'abc',
      'doi' => 'testdoi',
      'referenced_works_count' => references_count,
      'cited_by_count' => cited_by_count,
      'open_access' => { 'is_oa' => open_access_status }
    }
  end

  let(:cites_results) do
    [{ 'id' => 'https://openalex.org/W3171987103',
       'ids' => { 'openalex' => 'https://openalex.org/W3171987103',
                  'doi' => 'https://doi.org/10.1017/xps.2021.16' },
       'doi' => 'https://doi.org/10.1017/xps.2021.16', 'type' => 'article' }]
  end

  let(:cited_by_results) do
    [{ 'id' => 'https://openalex.org/W2163881983',
       'ids' => { 'openalex' => 'https://openalex.org/W2163881983',
                  'doi' => 'https://doi.org/10.1111/j.1467-9221.2006.00451.x' },
       'doi' => 'https://doi.org/10.1111/j.1467-9221.2006.00451.x', 'type' => 'article' }]
  end

  let(:mapped_record) { {} }
  let(:enhanced_record) { described_class.new(mapped_record:, doi: 'testdoi').add_metadata }
  let(:open_access_status) { true }

  before do
    allow(Clients::OpenAlex).to receive(:new).and_return(openalex_client)
    allow(openalex_client).to receive_messages(dataset_doi: openalex_dataset)
    allow(openalex_client).to receive(:query_relationship).with(relationship: 'cites',
                                                                id: 'abc').and_return(cites_results)
    allow(openalex_client).to receive(:query_relationship).with(relationship: 'cited_by',
                                                                id: 'abc').and_return(cited_by_results)
  end

  context 'when the original metadata has no related identifiers but OpenAlex returns related publications' do
    let(:references_count) { 1 }
    let(:cited_by_count) { 1 }

    it 'adds related publications to the mapped metadata record' do
      expect(enhanced_record['related_identifiers']).to include(hash_including('related_identifier' => 'W3171987103',
                                                                               'related_identifier_type' => 'OpenAlex',
                                                                               'relation_type' => 'IsCitedBy'))
      expect(enhanced_record['related_identifiers']).to include(hash_including(
                                                                  'related_identifier' => 'W2163881983',
                                                                  'relation_type' => 'Cites',
                                                                  'related_identifier_type' => 'OpenAlex'
                                                                ))
    end
  end

  context 'when the relationship count is zero' do
    let(:references_count) { 0 }
    let(:cited_by_count) { 0 }

    it 'does not add any related publications' do
      expect(enhanced_record).not_to have_key('related_identifiers')
    end
  end

  context 'when the metadata record already has related identifiers with no overlapping dois' do
    let(:references_count) { 1 }
    let(:cited_by_count) { 1 }
    let(:mapped_record) do
      {
        'related_identifiers' => [{ 'related_identifier' => 'https://testid' }]
      }
    end

    it 'does not add any related publications' do
      expect(enhanced_record['related_identifiers'].size).to eq(3)
    end
  end

  context 'when the metadata record has related identifiers with an overlapping doi' do
    let(:references_count) { 1 }
    let(:cited_by_count) { 1 }
    let(:mapped_record) do
      {
        'related_identifiers' => [{ 'related_identifier' => '10.1017/xps.2021.16' }]
      }
    end
    let(:overlap_doi) do
      {
        'related_identifer' => 'W3171987103',
        'related_identifier_type' => 'OpenAlex',
        'relation_type' => 'IsCitedBy'
      }
    end

    it 'does not add any related publications' do
      expect(enhanced_record['related_identifiers']).not_to include(hash_including(overlap_doi))
    end
  end

  context 'when open access status is true' do
    let(:references_count) { 0 }
    let(:cited_by_count) { 0 }

    it 'adds open access to the rights list' do
      expect(enhanced_record['rights_list']).to include({ 'rights' => 'Open access' })
    end
  end

  context 'when open access status is false' do
    let(:references_count) { 0 }
    let(:cited_by_count) { 0 }
    let(:open_access_status) { false }

    it 'adds open access to the rights list' do
      expect(enhanced_record['rights_list']).to include({ 'rights' => 'Not open access' })
    end
  end
end
