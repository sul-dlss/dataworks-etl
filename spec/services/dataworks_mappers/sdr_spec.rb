# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Sdr do
  subject(:metadata) { described_class.call(source:) }

  let(:cocina_json) { JSON.parse(File.read('spec/fixtures/sources/sdr.json')) }
  let(:source) { Cocina::Models::DROWithMetadata.new(cocina_json) }

  it 'maps the identifiers' do
    expect(metadata[:identifiers]).to include(
      { identifier: 'druid:vk217bh4910', identifier_type: 'DRUID' },
      { identifier: '10.25740/ppax-bf07', identifier_type: 'DOI' }
    )
  end

  it 'maps the creators' do
    expect(metadata[:creators]).to eq(
      [
        {
          name: 'Fouhey, David',
          name_type: 'Personal',
          affiliation: [
            {
              name: 'Electrical Engineering and Computer Science Department, University of Michigan'
            }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0001-5028-5161',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Jin, Meng',
          name_type: 'Personal',
          affiliation: [
            { name: 'SETI Institute' },
            { name: "Lockheed Martin Solar \u0026 Astrophysics Laboratory" }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-9672-3873',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Cheung, Mark',
          name_type: 'Personal',
          affiliation: [
            { name: "Lockheed Martin Solar \u0026 Astrophysics Laboratory" },
            { name: 'Hansen Experimental Physics Laboratory, Stanford University' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0003-2110-9753',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Munoz-Jaramillo, Abndres',
          name_type: 'Personal',
          affiliation: [
            { name: 'Southwest Research Institute' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-4716-0840',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Galvez, Richard',
          name_type: 'Personal',
          affiliation: [
            { name: 'Center for Data Science, New York University' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-4780-9566',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Thomas, Rajat',
          name_type: 'Personal',
          affiliation: [
            { name: 'Department of Psychiatry, University of Amsterdam' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-5362-4816',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Wright, Paul',
          name_type: 'Personal',
          affiliation: [
            { name: 'SUPA School of Physics and Astronomy, University of Glasgow' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0001-9021-611X',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Szenicer, Alexander',
          name_type: 'Personal',
          affiliation: [
            { name: 'University of Oxford, Department of Earth Sciences' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-4829-5739',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Bobra, Monica G.',
          name_type: 'Personal',
          affiliation: [
            { name: 'Hansen Experimental Physics Laboratory, Stanford University' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-5662-9604',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Liu, Yang',
          name_type: 'Personal',
          affiliation: [
            { name: 'Hansen Experimental Physics Laboratory, Stanford University' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-0671-689X',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        },
        {
          name: 'Mason, James',
          name_type: 'Personal',
          affiliation: [
            { name: 'NASA Goddard Space Flight Center' }
          ],
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0002-3783-5509',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org/'
            }
          ]
        }
      ]
    )
  end

  it 'maps the titles' do
    expect(metadata[:titles]).to eq(
      [
        {
          title: "2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
        }
      ]
    )
  end

  it 'maps the descriptions' do
    # rubocop:disable Layout/LineLength
    expect(metadata[:descriptions]).to eq(
      [
        {
          description: 'We present a curated dataset from the NASA Solar Dynamics Observatory (SDO) mission in a format suitable for machine learning research. Beginning from level 1 scientific products we have processed various instrumental corrections, downsampled to manageable spatial and temporal resolutions, and synchronized observations spatially and temporally. We anticipate this curated dataset will facilitate machine learning research in heliophysics and the physical sciences generally, increasing the scientific return of the SDO mission. This work is a deliverable of the 2018 NASA Frontier Development Lab program. This page includes data from 2010. Data from 2011-2018 are also available. See links to related items elsewhere on this page.',
          description_type: 'Abstract'
        }
      ]
    )
    # rubocop:enable Layout/LineLength
  end

  it 'maps the contributors' do
    expect(metadata[:contributors]).to eq(
      [
        {
          name: 'Lockheed Martin',
          name_type: 'Organizational'
        },
        {
          name: 'IBM',
          name_type: 'Organizational'
        }
      ]
    )
  end

  it 'maps the publication year' do
    expect(metadata[:publication_year]).to eq('2018')
  end

  it 'maps the subjects' do
    expect(metadata[:subjects]).to eq(
      [
        { subject: 'NASA' },
        { subject: 'Solar Dynamics Observatory (SDO)' },
        { subject: 'Atmospheric Imaging Assembly (AIA)' },
        { subject: 'Helioseismic and Magnetic Imager (HMI)' },
        { subject: 'Extreme Ultraviolet Variability Experiment (EVE)' },
        { subject: 'Heliophysics' },
        { subject: 'Astronomy' },
        { subject: 'Sun' },
        { subject: 'Solar Irradiance' },
        { subject: 'Solar Magnetic Field' },
        { subject: 'Solar EUV' },
        { subject: 'Machine Learning' },
        { subject: 'Computer Vision' },
        { subject: 'Deep Learning' },
        { subject: 'Python' }
      ]
    )
  end

  it 'maps the dates' do
    expect(metadata[:dates]).to eq(
      [
        {
          date: '2018',
          date_type: 'Created'
        },
        {
          date: '2018',
          date_type: 'Issued'
        }
      ]
    )
  end

  it 'maps the related identifiers' do
    expect(metadata[:related_identifiers]).to eq(
      [
        {
          related_identifier: '10.25740/sb4q-wj06',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/1vyz-b592',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/2zme-3q44',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/3jhw-x180',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/0fbp-re41',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/64cr-bc95',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/c8bw-ar96',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        },
        {
          related_identifier: '10.25740/pknx-5s37',
          related_identifier_type: 'DOI',
          relation_type: 'IsPreviousVersionOf'
        }
      ]
    )
  end

  it 'maps the access' do
    expect(metadata[:access]).to eq('Public')
  end

  it 'maps the rights' do
    # rubocop:disable Layout/LineLength
    expect(metadata[:rights_list]).to eq(
      [
        {
          rights: 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.',
          rights_uri: 'https://creativecommons.org/licenses/by/3.0/legalcode'
        }
      ]
    )
    # rubocop:enable Layout/LineLength
  end

  it 'maps the url' do
    expect(metadata[:url]).to eq('https://purl.stanford.edu/vk217bh4910')
  end

  it 'maps the provider' do
    expect(metadata[:provider]).to eq('SDR')
  end

  it 'maps the sizes' do
    expect(metadata[:sizes]).to eq(['439 GB'])
  end

  it 'maps the formats' do
    expect(metadata[:formats]).to eq(['application/x-gzip'])
  end

  context 'when the source is a hash' do
    let(:source) { cocina_json }

    it 'maps to a solr document' do
      expect(metadata).to be_a(Hash)
    end
  end
end
