# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Zenodo do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/zenodo.json')) }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(
      {
        identifiers: [
          { identifier: '4999985', identifier_type: 'ZenodoId' },
          { identifier: '10.5061/dryad.st6h9', identifier_type: 'DOI' }
        ],
        titles: [{ title: 'Data from: Mutational analysis of Rab3 function for controlling active zone protein' }],
        descriptions: [{
          description: 'At synapses, the release of neurotransmitter is regulated by molecular machinery.',
          description_type: 'Abstract'
        }],
        creators: [
          {
            affiliation: [{ name: 'Amherst College' }],
            name: 'Chen, Shirui',
            name_type: 'Personal'
          },
          {
            affiliation: [{ name: 'Amherst College' }],
            name_identifiers: [{ name_identifier: '0000-0001-9746-9021', name_identifier_scheme: 'ORCID' }],
            name: 'Gendelman, Hannah K.',
            name_type: 'Personal'
          },
          {
            affiliation: [{ name: 'Amherst College' }],
            name: 'Roche, John P.',
            name_type: 'Personal'
          }
        ],
        publication_year: '2016',
        subjects: [
          { subject: 'Drosophila' },
          { subject: 'protein distribution' }
        ],
        dates: [{ date: '2016-08-17', date_type: 'Issued' }],
        related_identifiers: [
          {
            related_identifier: '10.1371/journal.pone.0136938',
            relation_type: 'IsCitedBy',
            related_identifier_type: 'DOI'
          }
        ],
        sizes: ['1723999109 bytes'],
        version: '1.0',
        rights_list: [{ rights_identifier: 'cc-zero', rights_identifier_scheme: 'zenodo' }],
        funding_references: [
          {
            award_number: '5P01HL147823-03',
            award_title: 'Gut Microbiota and Cardiometabolic Diseases',
            funder_identifier: '10.13039/100000002',
            funder_identifier_type: 'DOI',
            funder_name: 'National Institutes of Health'
          },
          {
            award_number: '17CVD01',
            award_title: 'Gut Microbiome as a Target for the Treatment of Cardiometabolic Diseases',
            funder_name: 'Fondation Leducq'
          }
        ],
        url: 'https://doi.org/10.5061/dryad.st6h9',
        access: 'Public',
        provider: 'Zenodo'
      }
    )
  end
end
