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
        titles: [{ title: 'My title' }]
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
    let(:metadata) do
      {
        doi: '10.1234/5678',
        creators: [
          { name: 'A. Researcher' },
          {
            name: 'B. Researcher', name_type: 'Personal', given_name: 'B.', family_name: 'Researcher',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-2345-6789', name_identifier_scheme: 'ORCID',
                scheme_uri: 'https://orcid.org/'
              }
            ],
            affiliation: [
              { name: 'My institution', affiliation_identifier: 'https://ror.org/00f54p054', affiliation_identifier_scheme: 'ROR' }
            ]
          },
          { name: 'A. Organization' },
          {
            name: 'B. Organization', name_type: 'Organizational',
            name_identifiers: [{ name_identifier: 'https://ror.org/00f54p054' }],
            affiliation: [{ name: 'B. Parent Organization' }]
          }
        ],
        titles: [
          { title: 'My title' },
          { title: 'My subtitle', title_type: 'Subtitle' }
        ],
        descriptions: [
          { description: 'My description' },
          { description: 'My abstract', description_type: 'Abstract' }
        ],
        dates: [
          { date: '2023-01-01' },
          { date: '2023-01-02T19:20:30+01:00' },
          { date: '2023-01-03', date_type: 'Updated' }
        ],
        version: '1.0'
      }
    end

    it 'returns true for valid?' do
      expect(validator.valid?).to be true
    end

    it 'returns no errors' do
      expect(validator.errors).to be_empty
    end
  end

  context 'when metadata is invalid' do
    let(:metadata) do
      {
        titles: [],
        another_field: 'invalid'
      }
    end

    it 'returns false for valid?' do
      expect(validator.valid?).to be false
    end

    it 'returns errors' do
      expect(validator.errors).to eq(
        [
          'array size at `/titles` is less than: 1',
          'object property at `/another_field` is a disallowed additional property',
          'object at root is missing required properties: creators'
        ]
      )
    end
  end
end
