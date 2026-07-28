# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Sdr do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(file_fixture('sdr.json').read) }

  it 'maps the identifiers' do
    expect(metadata[:identifiers]).to include(
      { identifier: 'vk217bh4910', identifier_type: 'DRUID' },
      { identifier: '10.25740/ppax-bf07', identifier_type: 'DOI' }
    )
  end

  it 'sets the stanford project flag to true' do
    expect(metadata[:stanford_project]).to be_truthy
  end

  it 'maps the access contact email address' do
    expect(metadata[:access_contact]).to contain_exactly({ email: 'jth@stanford.edu' }, { email: 'jinmeng@lmsal.com' })
  end

  context 'with creators' do
    # sdr.json fixture has old-style affiliation data as notes; this one is newer
    # See: https://github.com/sul-dlss/cocina-models/issues/816
    let(:source) { JSON.parse(file_fixture('sdr_affiliations.json').read) }

    # cocina-models will forbid single-element structuredValues, so H3 will emit
    # an affiliation with an institution and no department as a flat value instead
    # of a one-element structuredValue.
    context 'when an affiliation has been flattened (institution only, no department)' do
      before do
        source['description']['contributor'][0]['affiliation'] = [
          {
            'value' => 'Stanford University',
            'identifier' => [
              {
                'type' => 'ROR',
                'uri' => 'https://ror.org/00f54p054',
                'source' => { 'code' => 'ror' }
              }
            ]
          }
        ]
      end

      it 'still maps the affiliation name and ROR identifier' do
        expect(metadata[:creators].first[:affiliation]).to eq(
          [
            {
              name: 'Stanford University',
              affiliation_identifier: 'https://ror.org/00f54p054',
              affiliation_identifier_scheme: 'ROR',
              scheme_uri: 'https://ror.org/'
            }
          ]
        )
      end
    end

    it 'maps the creators' do
      expect(metadata[:creators].first).to eq(
        {
          name: 'Ghosh, Sayak',
          given_name: 'Sayak',
          family_name: 'Ghosh',
          name_type: 'Personal',
          name_identifiers: [
            {
              name_identifier: 'https://orcid.org/0000-0003-4168-7198',
              name_identifier_scheme: 'ORCID',
              scheme_uri: 'https://orcid.org'
            }
          ],
          affiliation: [
            {
              name: 'Stanford University, Geballe Laboratory for Advanced Materials',
              affiliation_identifier: 'https://ror.org/00f54p054',
              affiliation_identifier_scheme: 'ROR',
              scheme_uri: 'https://ror.org/'
            },
            {
              name: 'Stanford University, Department of Applied Physics',
              affiliation_identifier: 'https://ror.org/00f54p054',
              affiliation_identifier_scheme: 'ROR',
              scheme_uri: 'https://ror.org/'
            }
          ]
        }
      )
    end
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
          name_type: 'Organizational',
          contributor_type: 'Other'
        },
        {
          name: 'IBM',
          name_type: 'Organizational',
          contributor_type: 'Other'
        }
      ]
    )
  end

  it 'falls back to the Stanford Digital Repository as the publisher' do
    expect(metadata[:publisher]).to eq({ name: 'Stanford Digital Repository' })
  end

  context 'when the record names a publisher' do
    before do
      source['description']['contributor'].push(
        {
          'name' => [{ 'value' => 'Some Other Publisher' }],
          'role' => [
            { 'value' => 'publisher', 'source' => { 'value' => 'DataCite properties' } }
          ]
        }
      )
    end

    it 'keeps the publisher from the record' do
      expect(metadata[:publisher]).to include(name: 'Some Other Publisher')
    end
  end

  it 'maps the publication year' do
    expect(metadata[:publication_year]).to eq('2018')
  end

  context 'when there is no publication year' do
    before do
      source['description']['event'] = []
    end

    it 'falls back to the metadata created year' do
      expect(metadata[:publication_year]).to eq('2024')
    end
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

  # rubocop:disable Layout/LineLength
  # Related items may not have identifiers but may have URLs
  it 'maps the related items' do
    expect(metadata[:related_items]).to eq(
      [
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/sb4q-wj06',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2011 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/1vyz-b592',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2012 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/2zme-3q44',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2013 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/3jhw-x180',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2014 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/0fbp-re41',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2015 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/64cr-bc95',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2016 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/c8bw-ar96',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2017 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: '10.25740/pknx-5s37',
            related_item_identifier_type: 'DOI'
          },
          relation_type: 'IsPreviousVersionOf',
          titles: [
            {
              title: "2018 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: 'https://github.com/edhlee/FLPedBrain',
            related_item_identifier_type: 'URL'
          },
          titles: [
            {
              title: 'FLPedBrain'
            }
          ]
        },
        {
          related_item_identifier: {
            related_item_identifier: 'https://purl.stanford.edu/zx935qw7203',
            related_item_identifier_type: 'URL'
          },
          titles: [
            {
              title: 'FLPedBrain with PURL'
            }
          ]
        }
      ]
    )
  end
  # rubocop:enable Layout/LineLength

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

  context 'when there is a date with structured value and other type' do
    before do
      source['description']['event'].push(
        {
          'date' => [
            {
              'structuredValue' => [
                { 'value' => '2018-01-01', 'type' => 'start' },
                { 'value' => '2019-01-01', 'type' => 'end' }
              ],
              'encoding' => { 'code' => 'edtf' },
              'type' => 'Special time',
              'note' => [
                { 'value' => 'Recorded by me' }
              ]
            }
          ]
        }
      )
    end

    it 'uses the start value and notes the type and any other notes' do
      expect(metadata[:dates]).to include(
        {
          date: '2018-01-01',
          date_type: 'Other',
          date_information: 'Special time; ended 2019-01-01; Recorded by me'
        }
      )
    end
  end

  context 'when there is an encoded date' do
    before do
      source['description']['event'].push(
        {
          'date' => [
            {
              'value' => '2018-01-01T00:00:00Z',
              'encoding' => { 'code' => 'iso8601' }
            }
          ]
        }
      )
    end

    it 'formats the date to match the schema' do
      expect(metadata[:dates]).to include(
        {
          date: '2018-01-01',
          date_type: 'Other'
        }
      )
    end
  end

  context 'when there is no version' do
    it 'does not set a version' do
      expect(metadata[:version]).to be_nil
    end
  end

  context 'when there is a version note' do
    before do
      source['description']['note'].push(
        {
          'type' => 'version',
          'value' => '1.0'
        }
      )
    end

    it 'maps the version' do
      expect(metadata[:version]).to eq('1.0')
    end
  end

  context 'when there is a DOI with no value but a URI' do
    before do
      source['description']['identifier'] = []
      source['description']['identifier'].push(
        {
          'type' => 'DOI',
          'uri' => 'https://doi.org/10.1234/5678'
        }
      )
    end

    it 'maps the DOI from the URI' do
      expect(metadata[:identifiers]).to include(
        {
          identifier: '10.1234/5678',
          identifier_type: 'DOI'
        }
      )
    end
  end

  context 'when there are related resources that are citations only' do
    before do
      source['description']['relatedResource'] = []
      source['description']['relatedResource'].push(
        {
          'type' => 'preceded by',
          'dataCiteRelationType' => 'Continues',
          'note' => [
            { 'value' => 'Some article related to the dataset' },
            { 'type' => 'preferred citation' }
          ]
        }
      )
    end

    it 'uses the citation and the datacite relation type' do
      expect(metadata[:related_items]).to include(
        {
          titles: [
            { title: 'Some article related to the dataset' }
          ],
          relation_type: 'Continues'
        }
      )
    end
  end

  # cocina_display 2.x's RelatedResource#to_s no longer falls back to note text,
  # so we surface the preferred citation ourselves. See sul-dlss/dataworks-etl#607.
  context 'when a related resource only has a preferred citation' do
    before do
      source['description']['relatedResource'] = []
      source['description']['relatedResource'].push(
        {
          'type' => 'referenced by',
          'note' => [
            { 'type' => 'preferred citation', 'value' => 'Smith, J. (2020). A paper. Journal of Things.' }
          ]
        }
      )
    end

    it 'uses the preferred citation as the title' do
      expect(metadata[:related_items]).to include(
        {
          titles: [
            { title: 'Smith, J. (2020). A paper. Journal of Things.' }
          ],
          relation_type: 'IsReferencedBy'
        }
      )
    end
  end

  context 'with contributors that provide funding information' do
    before do
      source['description']['contributor'].push(
        {
          'name' => [{ 'value' => 'NASA' }],
          'role' => [{ 'value' => 'funder' }],
          'identifier' => [
            {
              'type' => 'ROR',
              'value' => 'https://ror.org/03yrm5c26'
            }
          ]
        }
      )
    end

    it 'maps the contributor as a funding reference' do
      expect(metadata[:funding_references]).to include(
        {
          funder_name: 'NASA',
          funder_identifier: 'https://ror.org/03yrm5c26',
          funder_identifier_type: 'ROR'
        }
      )
    end
  end
end
