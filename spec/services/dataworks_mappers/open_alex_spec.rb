# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::OpenAlex do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/open_alex.json')) }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(
      {
        identifiers: [
          {
            identifier: 'https://openalex.org/W4395524397',
            identifier_type: 'OpenAlex'
          },
          {
            identifier: 'https://doi.org/10.15468/7zkca3',
            identifier_type: 'DOI'
          }
        ],
        titles: [{ title: 'TOPP Summary of SSM-derived Telemetry' }],
        creators: [
          {
            name: 'James E. Ganong',
            name_identifiers: [
              { name_identifier: 'https://openalex.org/A5110752267', name_identifier_scheme: 'OpenAlex' }
            ],
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/00f54p054',
                affiliation_identifier_scheme: 'ROR',
                name: 'Stanford University'
              }
            ]
          }
        ],
        publication_year: '2021',
        url: 'https://www.gbif.org/dataset/50914b57-6c66-4432-91c7-edbc7a296a9f',
        access: 'Public',
        provider: 'OpenAlex',
        subjects: [
          {
            subject: 'Inertial Sensor and Navigation'
          }
        ],
        language: 'en',
        rights_list: [{ rights_uri: 'https://openalex.org/licenses/cc-by-nc' }],
        related_identifiers: [
          {
            related_identifier: 'https://openalex.org/W1505862594',
            related_identifier_type: 'OpenAlex'
          },
          {
            related_identifier: 'https://openalex.org/W1572335475',
            related_identifier_type: 'OpenAlex'
          }
        ],
        funding_references: [
          {
            funder_identifier: 'https://openalex.org/F4320337442',
            funder_identifier_type: 'OpenAlex',
            funder_name: 'California Sea Grant, University of California, San Diego',
            award_number: 'R/OPCFISH-06'
          }
        ]
      }
    )
  end
end
