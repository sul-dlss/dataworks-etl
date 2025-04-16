# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksValidator do
  subject(:validator) { described_class.new(metadata:) }

  context 'when required metadata is valid' do
    let(:metadata) do
      {
        creators: [
          { name: 'A. Researcher' }
        ],
        titles: [{ title: 'My title' }],
        publication_year: '2023',
        identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }],
        url: 'https://example.com/my-dataset',
        access: 'Public',
        provider: 'DataCite'
      }
    end

    it 'returns true for valid?' do
      expect(validator.valid?).to be true
    end

    it 'returns no errors' do
      expect(validator.errors).to be_empty
    end
  end

  context 'when metadata is valid' do
    let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/full_metadata_mapped.json')) }

    it 'returns true for valid?' do
      expect(validator.valid?).to be true
    end

    it 'returns no errors' do
      expect(validator.errors).to be_empty
    end

    context 'when only a title element with specific type is found' do
      let(:metadata) do
        {
          creators: [
            { name: 'A. Researcher' }
          ],
          titles: [{ title: 'My title', title_type: 'Subtitle' }],
          publication_year: '2023',
          identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }],
          url: 'https://example.com/my-dataset',
          access: 'Public',
          provider: 'DataCite'
        }
      end

      it 'returns true for valid?' do
        expect(validator.valid?).to be true
      end
    end
  end

  context 'when metadata is invalid' do
    let(:metadata) do
      {
        titles: [],
        another_field: 'invalid',
        publication_year: '23'
      }
    end

    it 'returns false for valid?' do
      expect(validator.valid?).to be false
    end

    it 'returns errors' do
      expect(validator.errors).to eq(
        [
          'array size at `/titles` is less than: 1',
          'string at `/publication_year` does not match pattern: ^[1-2][0-9]{3}$',
          'object property at `/another_field` is a disallowed additional property',
          'object at root is missing required properties: creators, identifiers, url, access, provider'
        ]
      )
    end
  end
end
