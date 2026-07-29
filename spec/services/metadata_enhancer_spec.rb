# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataEnhancer do
  let(:openalex_client) { instance_double(Clients::OpenAlex) }
  let(:dataverse_client) { instance_double(Clients::Dataverse) }

  before do
    StanfordAuthor.create!(sunet_id: 123,
                           cap_profile_id: 345,
                           full_name: 'B. Researcher',
                           first_name: 'B.',
                           last_name: 'Researcher',
                           orcid: 'https://orcid.org/0000-0001-2345-6789',
                           email: 'test@test.com',
                           active: true,
                           departments: ['Test Department 1', 'Academic Areas', 'Test Department 2'])
    allow(Clients::OpenAlex).to receive(:new).and_return(openalex_client)
    allow(openalex_client).to receive(:dataset_doi).and_return({})
    allow(Clients::Dataverse).to receive(:new).and_return(dataverse_client)
    allow(dataverse_client).to receive(:dataset_doi).and_return({})
  end

  context 'when creators or contributors have ORCIDs that map to our Stanford authors table' do
    let(:mapped_record) { JSON.parse(File.read('spec/fixtures/mapped_datasets/full_metadata_mapped.json')) }
    let(:enhanced_record) { described_class.call(mapped_record:, doi: '10.1234/5678') }

    it 'adds profile id and department name for creators, dropping excluded departments' do
      creator = enhanced_record[:creators][1]
      expect(creator[:name_identifiers]).to include(hash_including('name_identifier' => '345',
                                                                   'name_identifier_scheme' => 'CAP'))
      expect(creator[:affiliation]).to include(hash_including('affiliation_department_name' => [
                                                                'Test Department 1', 'Test Department 2'
                                                              ]))
    end

    it 'adds profile id and department name for contributors, dropping excluded departments' do
      contributor = enhanced_record[:contributors][1]
      expect(contributor[:name_identifiers]).to include(hash_including('name_identifier' => '345',
                                                                       'name_identifier_scheme' => 'CAP'))
      expect(contributor[:affiliation]).to include(hash_including('affiliation_department_name' => [
                                                                    'Test Department 1', 'Test Department 2'
                                                                  ]))
    end
  end

  context "when all of an author's departments are excluded" do
    before do
      StanfordAuthor.find_by(cap_profile_id: 345)
                    .update!(departments: ['Academic Areas', 'DELETE NOT VALID'])
    end

    let(:mapped_record) do
      {
        titles: [{ title: 'My title' }],
        publication_year: '2023',
        identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }],
        url: 'https://example.com/my-dataset',
        access: 'Public',
        provider: 'DataCite',
        creators: [
          {
            name: 'Creator',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-2345-6789',
                name_identifier_scheme: 'ORCID'
              }
            ]
          }
        ]
      }
    end
    let(:enhanced_record) { described_class.call(mapped_record:, doi: '10.1234/5678') }

    it 'does not attach a affiliation block' do
      creator = enhanced_record[:creators][0]
      expect(creator[:name_identifiers]).to include(hash_including('name_identifier_scheme' => 'CAP'))
      expect(creator[:affiliation]).to be_blank
    end
  end

  context 'when provider metadata does not have Stanford University in affiliation' do
    let(:mapped_record) do
      {
        titles: [{ title: 'My title' }],
        publication_year: '2023',
        identifiers: [{ identifier: '10.1234/5678', identifier_type: 'DOI' }],
        url: 'https://example.com/my-dataset',
        access: 'Public',
        provider: 'DataCite',
        creators: [
          {
            name: 'Creator',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-2345-6789',
                name_identifier_scheme: 'ORCID'
              }
            ]
          }
        ]
      }
    end
    let(:enhanced_record) { described_class.call(mapped_record:, doi: '10.1234/5678') }

    it 'adds Stanford University affiliation block' do
      creator = enhanced_record[:creators][0]
      expect(creator['affiliation']).to include(hash_including('name' => 'Stanford University'))
    end
  end
end
