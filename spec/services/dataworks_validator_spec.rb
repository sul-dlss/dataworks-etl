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
    let(:metadata) do
      {
        creators: [
          { name: 'A. Researcher' },
          {
            name: 'B. Researcher', name_type: 'Personal', given_name: 'B.', family_name: 'Researcher',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-2345-6789', name_identifier_scheme: 'ORCID'
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
        publisher: {
          name: 'My publisher',
          schema_uri: 'https://ror.org/',
          publisher_identifier: 'https://ror.org/00f54p054', publisher_identifier_scheme: 'ROR'
        },
        publication_year: '2023',
        subjects: [
          { subject: 'My subject' },
          {
            subject: 'My subject 2',
            subject_scheme: 'Library of Congress Subject Headings (LCSH)',
            value_uri: 'https://id.loc.gov/authorities/subjects/sh85026447'
          }
        ],
        contributors: [
          { name: 'A. Contributor' },
          {
            name: 'B. Contributor', name_type: 'Personal', given_name: 'B.', family_name: 'Contributor',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-2345-6789', name_identifier_scheme: 'ORCID'
              }
            ],
            affiliation: [
              { name: 'My institution', affiliation_identifier: 'https://ror.org/00f54p054', affiliation_identifier_scheme: 'ROR' }
            ],
            contributor_type: 'DataCollector'
          },
          { name: 'A. Organization' },
          {
            name: 'B. Organization', name_type: 'Organizational',
            name_identifiers: [{ name_identifier: 'https://ror.org/00f54p054' }],
            affiliation: [{ name: 'B. Parent Organization' }],
            contributor_type: 'RegistrationAgency'
          }
        ],
        descriptions: [
          { description: 'My description' },
          { description: 'My abstract', description_type: 'Abstract' }
        ],
        dates: [
          { date: '2023-01-01' },
          { date: '2023-01-02T19:20:30+01:00' },
          { date: '2023-01-03', date_type: 'Updated' },
          { date: '2022-01-01/2022-12-31' },
          { date: '2022-11-25' },
          { date: '1973' },
          { date: '2008-06-08T00:00:00Z/2008-07-04T00:00:00Z' },
          { date: '2006-12-20T00:00:00.000Z/2023-10-06T23:59:59.999Z' },
          { date: '0600-01-01/1800-01-01' }
        ],
        language: 'en',
        identifiers: [
          { identifier: 'stanfordphs.prime_india:016c:v0_1', identifier_type: 'RedivisReference' },
          { identifier: '10.1234/5678', identifier_type: 'DOI' }
        ],
        related_identifiers: [
          { related_identifier: '10.1234/5678' },
          {
            related_identifier: '10.2345/6789',
            relation_type: 'IsCitedBy',
            resource_type_general: 'JournalArticle',
            related_identifier_type: 'DOI'
          }
        ],
        sizes: ['1.2 MB', '3 pages'],
        formats: ['application/pdf', '.pdf'],
        version: '1.0',
        rights_list: [
          { rights: 'My rights' },
          {
            rights: 'Creative Commons Attribution 4.0 International',
            rights_uri: 'https://creativecommons.org/licenses/by/4.0/',
            rights_identifier: 'CC-BY-4.0',
            rights_identifier_scheme: 'SPDX'
          },
          {
            rights_uri: 'https://creativecommons.org/licenses/by/4.0/'
          }
        ],
        funding_references: [
          { funder_name: 'My funder' },
          {
            funder_name: 'My other funder',
            funder_identifier: 'https://ror.org/00f54p054',
            funder_identifier_type: 'ROR',
            award_number: '123456',
            award_uri: 'https://doi.org/10.1234/5678',
            award_title: 'My award title'
          }
        ],
        url: 'https://example.com/my-dataset',
        variables: ['variable 1', 'variable 2'],
        data_use_statement: 'My data use statement',
        access: 'Restricted',
        provider: 'Zenodo'
      }
    end

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
