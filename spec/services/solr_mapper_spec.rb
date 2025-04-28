# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrMapper do
  subject(:solr_mapper) { described_class.new(metadata:, dataset_record_id: 123, dataset_record_set_id: 456) }

  context 'with full metadata record' do
    let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/full_metadata_mapped.json')) }

    # rubocop:disable Layout/LineLength
    describe '#call' do
      it 'maps to Solr metadata' do
        expect(solr_mapper.call).to eq(
          {
            id: 123,
            dataset_record_set_id_ss: 456,
            title_tsim: ['My title'],
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
            contributors_ids_ssim: ['https://orcid.org/0000-0001-2345-6789', 'https://ror.org/00f54p054'],
            contributors_tsim: ['A. Contributor', 'B. Contributor', 'A. Organization', 'B. Organization'],
            funders_ssim: ['My funder', 'My other funder'],
            funders_ids_sim: ['https://ror.org/00f54p054'],
            url_ss: 'https://example.com/my-dataset',
            contributors_struct_ss: '[{"name":"A. Contributor"},{"name":"B. Contributor","name_type":"Personal","given_name":"B.","family_name":"Contributor","name_identifiers":[{"name_identifier":"https://orcid.org/0000-0001-2345-6789","name_identifier_scheme":"ORCID"}],"affiliation":[{"name":"My institution","affiliation_identifier":"https://ror.org/00f54p054","affiliation_identifier_scheme":"ROR"}],"contributor_type":"DataCollector"},{"name":"A. Organization"},{"name":"B. Organization","name_type":"Organizational","name_identifiers":[{"name_identifier":"https://ror.org/00f54p054"}],"affiliation":[{"name":"B. Parent Organization"}],"contributor_type":"RegistrationAgency"}]',
            dates_struct_ss: '[{"date":"2023-01-01"},{"date":"2023-01-02T19:20:30+01:00"},{"date":"2023-01-03","date_type":"Updated"},{"date":"2022-01-01/2022-12-31"},{"date":"2022-11-25"},{"date":"1973"},{"date":"2008-06-08T00:00:00Z/2008-07-04T00:00:00Z"},{"date":"2006-12-20T00:00:00.000Z/2023-10-06T23:59:59.999Z"},{"date":"0600-01-01/1800-01-01"}]',
            funding_references_struct_ss: '[{"funder_name":"My funder"},{"funder_name":"My other funder","funder_identifier":"https://ror.org/00f54p054","funder_identifier_type":"ROR","award_number":"123456","award_uri":"https://doi.org/10.1234/5678","award_title":"My award title"}]',
            related_identifiers_struct_ss: '[{"related_identifier":"10.1234/5678"},{"related_identifier":"10.2345/6789","relation_type":"IsCitedBy","resource_type_general":"JournalArticle","related_identifier_type":"DOI"}]',
            rights_list_struct_ss: '[{"rights":"My rights"},{"rights":"Creative Commons Attribution 4.0 International","rights_uri":"https://creativecommons.org/licenses/by/4.0/","rights_identifier":"CC-BY-4.0","rights_identifier_scheme":"SPDX"},{"rights_uri":"https://creativecommons.org/licenses/by/4.0/"}]',
            related_ids_sim: ['10.1234/5678', '10.2345/6789']
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
            id: 123,
            dataset_record_set_id_ss: 456,
            title_tsim: ['My title'],
            access_ssi: 'Public',
            provider_ssi: 'DataCite',
            provider_identifier_ssi: '10.1234/5678',
            doi_ssi: '10.1234/5678',
            url_ss: 'https://example.com/my-dataset'
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
            }
          ]
        }
      end

      it 'retrieves descriptions of type abstract or without a type' do
        expect(solr_mapper.descriptions_field).to eq(['My description', 'My abstract'])
      end
    end

    context 'with description with length greater than accepted by Solr' do
      let(:metadata) do
        {
          descriptions: [
            {
              description: SecureRandom.alphanumeric(40_000)
            }
          ]
        }
      end

      it 'truncates the description string length correctly' do
        expect(solr_mapper.descriptions_field[0].length).to eq(32_766)
      end
    end
  end

  describe '#doi_field' do
    context 'with no doi prefix in source DOI value' do
      let(:metadata) do
        {
          identifiers: [{ identifier: 'redivis:id', identifier_type: 'Redivis' },
                        { identifier: '10.1234/5678', identifier_type: 'DOI' }]
        }
      end

      it 'retrieves the DOI field' do
        expect(solr_mapper.doi_field).to eq('10.1234/5678')
      end
    end

    context 'with doi prefix in source DOI value' do
      let(:metadata) do
        {
          identifiers: [{ identifier: 'doi:10.1234/5678', identifier_type: 'DOI' }]
        }
      end

      it 'retrieves the DOI field' do
        expect(solr_mapper.doi_field).to eq('10.1234/5678')
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
end
