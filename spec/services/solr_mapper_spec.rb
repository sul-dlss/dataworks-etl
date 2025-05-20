# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrMapper do
  subject(:solr_mapper) do
    described_class.new(metadata:, doi: '10.1234/5678', id: id, load_id: 'abc123', provider_identifiers_map:)
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
      it 'maps to Solr metadata' do
        expect(solr_mapper.call).to eq(
          {
            id: 'redivis-123',
            load_id_ssi: 'abc123',
            title_tsim: ['My title V1.0'],
            subtitle_tsim: ['My subtitle'],
            alternative_title_tsim: ['My alt title'],
            translate_title_tsim: ['My translated title'],
            other_title_tsim: ['My other title'],
            access_ssi: 'Restricted',
            provider_ssi: 'Redivis',
            provider_identifier_ssi: 'stanfordphs.prime_india:016c:v0_1',
            doi_ssi: '10.1234/5678',
            descriptions_tsim: ['My description', 'My abstract'],
            creators_struct_ss: '[{"name":"A. Researcher"},{"name":"B. Researcher","name_type":"Personal","given_name":"B.","family_name":"Researcher","name_identifiers":[{"name_identifier":"https://orcid.org/0000-0001-2345-6789","name_identifier_scheme":"ORCID"}],"affiliation":[{"name":"My institution","affiliation_identifier":"https://ror.org/00f54p054","affiliation_identifier_scheme":"ROR"}]},{"name":"A. Organization"},{"name":"B. Organization","name_type":"Organizational","name_identifiers":[{"name_identifier":"https://ror.org/00f54p054"}],"affiliation":[{"name":"B. Parent Organization"}]}]',
            creators_ssim: ['A. Researcher', 'B. Researcher', 'A. Organization', 'B. Organization'],
            creators_ids_sim: ['https://orcid.org/0000-0001-2345-6789', 'https://ror.org/00f54p054'],
            contributors_ids_sim: ['https://orcid.org/0000-0001-2345-6789', 'https://ror.org/00f54p054'],
            contributors_ssim: ['A. Contributor', 'B. Contributor', 'A. Organization', 'B. Organization'],
            funders_ssim: ['My funder', 'My other funder'],
            funders_ids_sim: ['https://ror.org/00f54p054'],
            url_ss: 'https://example.com/my-dataset',
            contributors_struct_ss: '[{"name":"A. Contributor"},{"name":"B. Contributor","name_type":"Personal","given_name":"B.","family_name":"Contributor","name_identifiers":[{"name_identifier":"https://orcid.org/0000-0001-2345-6789","name_identifier_scheme":"ORCID"}],"affiliation":[{"name":"My contributor institution","affiliation_identifier":"https://ror.org/00f54p054","affiliation_identifier_scheme":"ROR"}],"contributor_type":"DataCollector"},{"name":"A. Organization"},{"name":"B. Organization","name_type":"Organizational","name_identifiers":[{"name_identifier":"https://ror.org/00f54p054"}],"affiliation":[{"name":"B. Parent Organization"}],"contributor_type":"RegistrationAgency"}]',
            dates_struct_ss: '[{"date":"2023-01-01"},{"date":"2023-01-02T19:20:30+01:00"},{"date":"2023-01-03","date_type":"Updated"},{"date":"2022-01-01/2022-12-31"},{"date":"2022-11-25","date_type":"Coverage"},{"date":"1973"},{"date":"2008-06-08T00:00:00Z/2008-07-04T00:00:00Z"},{"date":"2006-12-20T00:00:00.000Z/2023-10-06T23:59:59.999Z"},{"date":"0600-01-01/1800-01-01"}]',
            funding_references_struct_ss: '[{"funder_name":"My funder"},{"funder_name":"My other funder","funder_identifier":"https://ror.org/00f54p054","funder_identifier_type":"ROR","award_number":"123456","award_uri":"https://doi.org/10.1234/5678","award_title":"My award title"}]',
            related_identifiers_struct_ss: '[{"related_identifier":"10.1234/5678"},{"related_identifier":"10.2345/6789","relation_type":"IsCitedBy","resource_type_general":"JournalArticle","related_identifier_type":"DOI"}]',
            rights_list_struct_ss: '[{"rights":"My rights"},{"rights":"Creative Commons Attribution 4.0 International","rights_uri":"https://creativecommons.org/licenses/by/4.0/","rights_identifier":"CC-BY-4.0","rights_identifier_scheme":"SPDX"},{"rights_uri":"https://creativecommons.org/licenses/by/4.0/"}]',
            related_ids_sim: ['10.1234/5678', '10.2345/6789'],
            publisher_ssi: 'My publisher',
            publisher_id_sim: 'https://ror.org/00f54p054',
            publication_year_isi: 2023,
            subjects_ssim: ['My subject', 'My subject 2'],
            language_ssi: 'en',
            sizes_ssm: ['1.2 MB', '3 pages'],
            formats_ssim: ['application/pdf', '.pdf'],
            version_ss: '1.0',
            rights_uris_sim: ['https://creativecommons.org/licenses/by/4.0/'],
            affiliation_names_sim: ['My institution', 'B. Parent Organization', 'My contributor institution'],
            variables_tsim: ['variable 1', 'variable 2'],
            temporal_isim: [2022],
            courses_sim: ['CS246'],
            provider_identifier_map_struct_ss: '{"DataCite":"10.1234/5678","Redivis":"redivis-123"}',
            geo_place_ssim: ['Vancouver, British Columbia, Canada', 'Victoria, British Columbia, Canada']
          }
        )
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
      it 'maps to Solr metadata' do
        expect(solr_mapper.call).to eq(
          {
            id: 'redivis-123',
            load_id_ssi: 'abc123',
            title_tsim: ['My title'],
            access_ssi: 'Public',
            provider_ssi: 'DataCite',
            provider_identifier_ssi: '10.1234/5678',
            doi_ssi: '10.1234/5678',
            url_ss: 'https://example.com/my-dataset',
            publication_year_isi: 2023,
            courses_sim: ['CS246']
          }
        )
      end
    end
  end

  describe '#provider_identifier_field' do
    context 'with DataCite as provider' do
      let(:metadata) do
        {
          provider: 'DataCite',
          identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }]
        }
      end

      it 'retrieves DOI for DataCite' do
        expect(solr_mapper.provider_identifier_field).to eq('10.1234/5678')
      end
    end

    context 'with Dryad as provider' do
      let(:metadata) do
        {
          provider: 'Dryad',
          identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }]
        }
      end

      it 'retrieves DOI for Dryad' do
        expect(solr_mapper.provider_identifier_field).to eq('10.1234/5678')
      end
    end

    context 'with Zenodo as provider' do
      let(:metadata) do
        {
          provider: 'Zenodo',
          identifiers: [{ identifier: '10.1234/5678', identifier_type: 'ZenodoId' }]
        }
      end

      it 'retrieves the Zenodo identifier' do
        expect(solr_mapper.provider_identifier_field).to eq('10.1234/5678')
      end
    end

    context 'with SDR as provider' do
      let(:metadata) do
        {
          provider: 'SDR',
          identifiers: [{ identifier: 'druid:123ab456', identifier_type: 'DRUID' }]
        }
      end

      it 'retrieves the SDR DRUID' do
        expect(solr_mapper.provider_identifier_field).to eq('druid:123ab456')
      end
    end
  end

  describe '#descriptions_field' do
    context 'with descriptions of multiple types' do
      let(:metadata) do
        {
          descriptions: [
            {
              description: 'My description'
            },
            {
              description: 'My abstract',
              description_type: 'Abstract'
            },
            {
              description: 'My methods',
              description_type: 'Methods'
            },
            {
              description: 'Other',
              description_type: 'Other'
            },
            {
              description: 'Series information',
              description_type: 'SeriesInformation'
            },
            {
              description: 'Table of contents',
              description_type: 'TableOfContents'
            },
            {
              description: 'Technical info',
              description_type: 'TechnicalInfo'
            }
          ]
        }
      end

      it 'retrieves descriptions of type abstract or without a type' do
        expect(solr_mapper.descriptions_field).to eq(['My description', 'My abstract'])
      end

      it 'retrieves descriptions of type Methods' do
        expect(solr_mapper.descriptions_by_type_field(['Methods'])).to eq(['My methods'])
      end

      it 'retrieves descriptions of other types' do
        expect(solr_mapper.descriptions_by_type_field(%w[Other SeriesInformation TableOfContents
                                                         TechnicalInfo])).to eq(['Other', 'Series information',
                                                                                 'Table of contents', 'Technical info'])
      end
    end

    context 'with description with length greater than accepted by Solr' do
      let(:metadata) do
        {
          descriptions: [
            {
              description: SecureRandom.alphanumeric(40_000)
            },
            {
              description: SecureRandom.alphanumeric(40_000),
              description_type: 'Methods'
            }
          ]
        }
      end

      it 'truncates the description string length correctly for abstracts' do
        expect(solr_mapper.descriptions_field[0].length).to eq(SolrMapper::TEXT_LIMIT)
      end

      it 'truncates the description string length correctly for methods' do
        expect(solr_mapper.descriptions_by_type_field(['Methods'])[0].length).to eq(SolrMapper::TEXT_LIMIT)
      end
    end
  end

  describe '#person_or_organization_ids_field' do
    let(:metadata) do
      {
        creators: [
          {
            name_identifiers: [
              {
                name_identifier: 'ABC'
              },
              {
                name_identifier: 'CDE'
              }
            ]
          },
          {
            name_identifiers: [
              {
                name_identifier: 'FGH'
              }
            ]
          }
        ]
      }
    end

    it 'retrieves name identifiers as list' do
      expect(solr_mapper.person_or_organization_ids_field('creators')).to eq(%w[ABC CDE FGH])
    end
  end

  context 'with empty funding references field' do
    let(:metadata) do
      {}
    end

    it 'returns no funder names when funding references is empty' do
      expect(solr_mapper.funders_field).to eq([])
    end

    it 'returns no funder ids when funding references is empty' do
      expect(solr_mapper.funders_ids_field).to eq([])
    end
  end

  context 'with temporal coverage dates' do
    let(:metadata) do
      {
        dates: [
          date:,
          date_type: 'Coverage'
        ]
      }
    end

    context 'with YYYY format' do
      let(:date) { '2024' }

      it 'returns the year correctly with YYYY format' do
        expect(solr_mapper.temporal_field).to eq([2024])
      end
    end

    context 'with YYYY-MM-DD format' do
      let(:date) { '2024-02-02' }

      it 'returns the year correctly with YYYY format' do
        expect(solr_mapper.temporal_field).to eq([2024])
      end
    end

    context 'with YYYY- MM-DDThh:mm:ssTZD format' do
      let(:date) { '2023-01-02T19:20:30+01:00' }

      it 'returns the year correctly with YYYY format' do
        expect(solr_mapper.temporal_field).to eq([2023])
      end
    end

    context 'with date range format' do
      let(:date) { '2023-01-02T19:20:30+01:00/2025-01-01' }

      it 'returns the sequence of years correctly representing the range' do
        expect(solr_mapper.temporal_field).to eq([2023, 2024, 2025])
      end
    end
  end

  describe '#transform_id' do
    let(:metadata) { {} }
    let(:id) { '10.1234/5678' }

    it 'replaces characters correctly' do
      expect(solr_mapper.transform_id).to eq('10_1234_5678')
    end
  end
end
