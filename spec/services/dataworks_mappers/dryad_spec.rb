# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Dryad do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/dryad.json')) }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(
      {
        titles: [{ title: '10Be concentrations constraining surface age and valley growth ' \
                          'rate in a seepage-derived drainage network in the Apalachicola River basin, Florida' }],
        creators: [
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/00f54p054',
                affiliation_identifier_scheme: 'ROR',
                name: 'Stanford University'
              }
            ],
            name: 'Emma Harrison',
            name_identifiers: [
              { name_identifier: '0000-0003-1308-7523', name_identifier_scheme: 'ORCID' }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/01485tq96',
                affiliation_identifier_scheme: 'ROR',
                name: 'University of Wyoming'
              }
            ],
            name: 'Brandon McElroy',
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/00f54p054',
                affiliation_identifier_scheme: 'ROR',
                name: 'Stanford University'
              }
            ],
            name: 'Jane Willenbring',
            name_type: 'Personal'
          }
        ],
        publication_year: '2022',
        identifiers: [{ identifier: 'doi:10.5061/dryad.bvq83bk8p', identifier_type: 'DOI' }],
        url: 'http://datadryad.org/dataset/doi:10.5061/dryad.bvq83bk8p',
        access: 'Public',
        provider: 'Dryad',
        descriptions: [
          { description: 'TEST ABSTRACT', description_type: 'Abstract' },
          { description: 'TEST METHODS', description_type: 'Methods' },
          { description: 'TEST USAGE NOTES', description_type: 'Other' }
        ],
        dates: [
          { date: '2022-03-02', date_type: 'Issued' },
          { date: '2022-03-02', date_type: 'Updated' }
        ],
        subjects: [{ subject: 'Geomorphology and cosmogenic radionuclides' }],
        sizes: ['77298 KB'],
        related_identifiers: [{ related_identifier: '2169-9003', related_identifier_type: 'ISSN' }],
        rights_list: [{ rights_uri: 'https://spdx.org/licenses/CC0-1.0.html' }],
        funding_references: [
          {
            award_number: '1848637',
            funder_identifier: 'https://ror.org/021nxhr62',
            funder_identifier_type: 'ROR',
            funder_name: 'National Science Foundation'
          }
        ],
        version: '3'
      }
    )
  end
end
