# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VertexMapper do
  subject(:doc) do
    described_class.new(metadata:, doi: '10.1234/5678', id: id, load_id: 'abc123', provider_identifiers_map:).call
  end

  let(:id) { 'redivis-123' }

  let(:provider_identifiers_map) { {} }

  context 'with full metadata record' do
    let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/full_metadata_mapped.json')) }

    let(:provider_identifiers_map) do
      {
        'DataCite' => '10.1234/5678',
        'Redivis' => 'redivis-123'
      }
    end

    # rubocop:disable Layout/LineLength
    describe '#call' do
      it 'maps to vertex metadata' do
        expect(doc.except(:text)).to eq(
          {
            id: 'redivis-123',
            access: 'Restricted',
            description: 'My description',
            other_descriptions: ['My abstract'],
            provider: 'Redivis',
            doi: '10.1234/5678',
            title: 'My title',
            other_titles: ['My subtitle', 'My alt title', 'My translated title', 'My other title'],
            provider_identifier: 'stanfordphs.prime_india:016c:v0_1',
            contributors: ['A. Researcher', 'B. Researcher', 'A. Organization', 'B. Organization', 'A. Contributor', 'B. Contributor', 'A. Organization', 'B. Organization'],
            contributors_ids: ['https://orcid.org/0000-0001-2345-6789', 'https://ror.org/00f54p054', 'https://orcid.org/0000-0001-2345-6789', 'https://ror.org/00f54p054'],
            url: 'https://example.com/my-dataset',
            subjects: ['My subject', 'My subject 2']
          }
        )
        expect(doc[:text]).to start_with('A. Researcher B. Researcher Personal B. Researcher')
      end
    end
    # rubocop:enable Layout/LineLength
  end

  context 'with minimal metadata record' do
    let(:metadata) do
      {
        titles: [{ title: 'My title' }],
        publication_year: '2023',
        identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }],
        url: 'https://example.com/my-dataset',
        access: 'Public',
        provider: 'DataCite'
      }
    end

    describe '#call' do
      it 'maps to vertex metadata' do
        expect(doc).to eq(
          {
            access: 'Public',
            doi: '10.1234/5678',
            id: 'redivis-123',
            provider: 'DataCite',
            provider_identifier: '10.1234/5678',
            text: 'My title 2023 10.1234/5678 DOI https://example.com/my-dataset Public DataCite',
            title: 'My title',
            url: 'https://example.com/my-dataset'
          }
        )
      end
    end
  end
end
