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
            provider_identifier_ssim: ['stanfordphs.prime_india:016c:v0_1'],
            doi_ssi: '10.1234/5678',
            descriptions_tsim: ['My description', 'My abstract'],
            creators_struct_ss: '[{"name":"A. Researcher"},{"name":"B. Researcher","name_type":"Personal","given_name":"B.","family_name":"Researcher","name_identifiers":[{"name_identifier":"https://orcid.org/0000-0001-2345-6789","name_identifier_scheme":"ORCID"}],"affiliation":[{"name":"My institution","affiliation_identifier":"https://ror.org/00f54p054","affiliation_identifier_scheme":"ROR"}]},{"name":"A. Organization"},{"name":"B. Organization","name_type":"Organizational","name_identifiers":[{"name_identifier":"https://ror.org/00f54p054"}],"affiliation":[{"name":"B. Parent Organization"}]}]'
          }
        )
      end
    end
    # rubocop:enable Layout/LineLength
  end

  context 'with provider reference fields that us different formats' do
    let(:solr_mapped) do
      {
        id: 123,
        dataset_record_set_id_ss: 456,
        access_ssi: 'Public',
        provider_ssi: provider,
        title_tsim: ['My title'],
        subtitle_tsim: [],
        alternative_title_tsim: [],
        translate_title_tsim: [],
        other_title_tsim: [],
        descriptions_tsim: [],
        creators_struct_ss: '[{"name":"A. Researcher"}]',
        provider_identifier_ssim: provider_identifiers,
        doi_ssi: doi
      }
    end

    context 'with DataCite as provider' do
      let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/datacite_mapped.json')) }
      let(:provider) { 'DataCite' }
      let(:provider_identifiers) { ['10.1234/5678'] }
      let(:doi) { '10.1234/5678' }

      it 'maps correctly for DataCite' do
        expect(solr_mapper.call).to eq(solr_mapped)
      end
    end

    context 'with Zenodo as provider' do
      let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/zenodo_mapped.json')) }
      let(:provider) { 'Zenodo' }
      let(:provider_identifiers) { ['10.1234/5678'] }
      let(:doi) { '' }

      it 'maps correctly for DataCite' do
        expect(solr_mapper.call).to eq(solr_mapped)
      end
    end
  end

  context 'with different description types' do
    let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/multiple_descriptions_mapped.json')) }
    let(:solr_mapped) do
      {
        id: 123,
        dataset_record_set_id_ss: 456,
        access_ssi: 'Public',
        provider_ssi: 'Zenodo',
        title_tsim: ['My title'],
        subtitle_tsim: [],
        alternative_title_tsim: [],
        translate_title_tsim: [],
        other_title_tsim: [],
        descriptions_tsim: ['My description', 'My abstract'],
        creators_struct_ss: '[{"name":"A. Researcher"}]',
        provider_identifier_ssim: ['10.1234/5678'],
        doi_ssi: ''
      }
    end

    it 'maps correctly for multiple descriptions of different types' do
      expect(solr_mapper.call).to eq(solr_mapped)
    end
  end

  context 'with very long description text' do
    let(:metadata) { JSON.parse(File.read('spec/fixtures/mapped_datasets/longtext_mapped.json')) }
    let(:solr_mapped) do
      {
        id: 123,
        dataset_record_set_id_ss: 456,
        access_ssi: 'Public',
        provider_ssi: 'Zenodo',
        title_tsim: ['My title'],
        subtitle_tsim: [],
        alternative_title_tsim: [],
        translate_title_tsim: [],
        other_title_tsim: [],
        descriptions_tsim: [metadata['descriptions'][0]['description'].truncate(32_766)],
        creators_struct_ss: '[{"name":"A. Researcher"}]',
        provider_identifier_ssim: ['10.1234/5678'],
        doi_ssi: ''
      }
    end

    it 'maps correctly for description text that is longer than allowable Solr field length' do
      expect(solr_mapper.call).to eq(solr_mapped)
    end
  end
end
