# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Datacite do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/datacite.json')) }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(
      {
        creators: [
          {
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_type: 'Personal',
            affiliation: [
              {
                name: 'ExampleAffiliation',
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR'
              }
            ],
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ]
          },
          {
            name: 'ExampleOrganization',
            name_type: 'Organizational',
            name_identifiers: [
              {
                name_identifier: 'https://ror.org/04wxnsj81',
                name_identifier_scheme: 'ROR'
              }
            ]
          }
        ],
        titles: [
          { title: 'Example Title' },
          { title: 'Example Subtitle', title_type: 'Subtitle' },
          { title: 'Example TranslatedTitle', title_type: 'TranslatedTitle' },
          { title: 'Example AlternativeTitle', title_type: 'AlternativeTitle' }
        ],
        publisher: {
          name: 'Example Publisher',
          publisher_identifier: 'https://ror.org/04z8jg394',
          publisher_identifier_scheme: 'ROR'
        },
        publication_year: '2023',
        subjects: [
          {
            subject: 'Digital curation and preservation',
            subject_scheme: 'Australian and New Zealand Standard Research Classification (ANZSRC), 2020'
          },
          { subject: 'Example Subject' },
          {
            subject: 'Buddhist civilization',
            subject_scheme: 'Library of Congress Subject Headings (LCSH)',
            value_uri: 'https://id.loc.gov/authorities/subjects/sh85026447'
          }
        ],
        contributors: [
          {
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_type: 'Personal',
            contributor_type: 'ContactPerson',
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ]
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'DataCollector',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'DataCurator',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'DataManager',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            contributor_type: 'Distributor',
            name: 'ExampleOrganization',
            name_identifiers: [
              {
                name_identifier: 'https://ror.org/03yrm5c26',
                name_identifier_scheme: 'ROR'
              }
            ],
            name_type: 'Organizational'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'Editor',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            contributor_type: 'HostingInstitution',
            name: 'ExampleOrganization',
            name_identifiers: [
              {
                name_identifier: 'https://ror.org/03yrm5c26',
                name_identifier_scheme: 'ROR'
              }
            ],
            name_type: 'Organizational'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'Producer',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'ProjectLeader',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'ProjectManager',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'ProjectMember',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            contributor_type: 'RegistrationAgency',
            name: 'DataCite',
            name_identifiers: [
              {
                name_identifier: 'https://ror.org/04wxnsj81',
                name_identifier_scheme: 'ROR'
              }
            ],
            name_type: 'Organizational'
          },
          {
            contributor_type: 'RegistrationAuthority',
            name: 'International DOI Foundation',
            name_type: 'Organizational'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'RelatedPerson',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'Researcher',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          { affiliation: [
              {
                affiliation_identifier: 'https://ror.org/03yrm5c26',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleOrganization'
              }
            ],
            contributor_type: 'ResearchGroup',
            name: 'ExampleContributor' },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'RightsHolder',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/03yrm5c26',
                affiliation_identifier_scheme: 'ROR',
                name: 'https://ror.org/03yrm5c26'
              }
            ],
            contributor_type: 'Sponsor',
            name: 'ExampleContributor'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'Supervisor',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          },
          {
            contributor_type: 'WorkPackageLeader',
            name: 'ExampleOrganization',
            name_identifiers: [
              {
                name_identifier: 'https://ror.org/03yrm5c26',
                name_identifier_scheme: 'ROR'
              }
            ],
            name_type: 'Organizational'
          },
          {
            affiliation: [
              {
                affiliation_identifier: 'https://ror.org/04wxnsj81',
                affiliation_identifier_scheme: 'ROR',
                name: 'ExampleAffiliation'
              }
            ],
            contributor_type: 'Other',
            family_name: 'ExampleFamilyName',
            given_name: 'ExampleGivenName',
            name: 'ExampleFamilyName, ExampleGivenName',
            name_identifiers: [
              {
                name_identifier: 'https://orcid.org/0000-0001-5727-2427',
                name_identifier_scheme: 'ORCID'
              }
            ],
            name_type: 'Personal'
          }
        ],
        descriptions: [
          {
            description: 'Example Abstract',
            description_type: 'Abstract'
          },
          {
            description: 'Example Methods',
            description_type: 'Methods'
          },
          {
            description: 'Example SeriesInformation',
            description_type: 'SeriesInformation'
          },
          {
            description: 'Example TableOfContents',
            description_type: 'TableOfContents'
          },
          {
            description: 'Example TechnicalInfo',
            description_type: 'TechnicalInfo'
          },
          {
            description: 'Example Other',
            description_type: 'Other'
          }
        ],
        dates: [
          { date: '2023-01-01', date_type: 'Accepted' },
          { date: '2023-01-01', date_type: 'Available' },
          { date: '2023-01-01', date_type: 'Copyrighted' },
          { date: '2022-01-01/2022-12-31', date_type: 'Collected' },
          { date: '2023-01-01', date_type: 'Created' },
          { date: '2023-01-01', date_type: 'Issued' },
          { date: '2023-01-01', date_type: 'Submitted' },
          { date: '2023-01-01', date_type: 'Updated' },
          { date: '2023-01-01', date_type: 'Valid' },
          { date: '2023-01-01', date_type: 'Withdrawn' },
          { date: '2023-01-01', date_type: 'Other' }
        ],
        language: 'en',
        version: '1',
        identifiers: [
          { identifier: '10.82433/b09z-4k37', identifier_type: 'DOI' },
          { identifier: '12345', identifier_type: 'Local accession number' }
        ],
        url: 'https://example.com/',
        provider: 'DataCite',
        access: 'Public',
        sizes: [
          '1 MB',
          '90 pages'
        ],
        formats: [
          'application/xml',
          'text/plain'
        ],
        rights_list: [
          {
            rights: 'Creative Commons Attribution 4.0 International',
            rights_uri: 'https://creativecommons.org/licenses/by/4.0/legalcode',
            rights_identifier: 'cc-by-4.0',
            rights_identifier_scheme: 'SPDX'
          }
        ],
        funding_references: [
          {
            award_uri: 'https://example.com/example-award-uri',
            award_title: 'Example AwardTitle',
            funder_name: 'Example Funder',
            award_number: '12345',
            funder_identifier: 'https://doi.org/10.13039/501100000780',
            funder_identifier_type: 'Crossref Funder ID'
          }
        ],
        related_identifiers: [
          {
            relation_type: 'IsCitedBy',
            related_identifier: 'ark:/13030/tqb3kh97gh8w',
            resource_type_general: 'Audiovisual',
            related_identifier_type: 'ARK'
          },
          {
            relation_type: 'Cites',
            related_identifier: 'arXiv:0706.0001',
            resource_type_general: 'Book',
            related_identifier_type: 'arXiv'
          },
          {
            relation_type: 'IsSupplementTo',
            related_identifier: '2018AGUFM.A24K..07S',
            resource_type_general: 'BookChapter',
            related_identifier_type: 'bibcode'
          },
          {
            relation_type: 'IsSupplementedBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Collection',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsContinuedBy',
            related_identifier: '9783468111242',
            resource_type_general: 'ComputationalNotebook',
            related_identifier_type: 'EAN13'
          },
          {
            relation_type: 'Continues',
            related_identifier: '1562-6865',
            resource_type_general: 'ConferencePaper',
            related_identifier_type: 'EISSN'
          },
          {
            relation_type: 'Describes',
            related_identifier: '10013/epic.10033',
            resource_type_general: 'ConferenceProceeding',
            related_identifier_type: 'Handle'
          },
          {
            relation_type: 'IsDescribedBy',
            related_identifier: 'IECUR0097',
            resource_type_general: 'DataPaper',
            related_identifier_type: 'IGSN'
          },
          {
            relation_type: 'HasMetadata',
            related_identifier: '978-3-905673-82-1',
            resource_type_general: 'Dataset',
            related_identifier_type: 'ISBN'
          },
          {
            relation_type: 'IsMetadataFor',
            related_identifier: '0077-5606',
            resource_type_general: 'Dissertation',
            related_identifier_type: 'ISSN'
          },
          {
            relation_type: 'HasVersion',
            related_identifier: '0A9 2002 12B4A105 7',
            resource_type_general: 'Event',
            related_identifier_type: 'ISTC'
          },
          {
            relation_type: 'IsVersionOf',
            related_identifier: '1188-1534',
            resource_type_general: 'Image',
            related_identifier_type: 'LISSN'
          },
          {
            relation_type: 'IsNewVersionOf',
            related_identifier: 'urn:lsid:ubio.org:namebank:11815',
            resource_type_general: 'InteractiveResource',
            related_identifier_type: 'LSID'
          },
          {
            relation_type: 'IsPreviousVersionOf',
            related_identifier: '12082125',
            resource_type_general: 'Journal',
            related_identifier_type: 'PMID'
          },
          {
            relation_type: 'IsPartOf',
            related_identifier: 'http://purl.oclc.org/foo/bar',
            resource_type_general: 'JournalArticle',
            related_identifier_type: 'PURL'
          },
          {
            relation_type: 'HasPart',
            related_identifier: '123456789999',
            resource_type_general: 'Model',
            related_identifier_type: 'UPC'
          },
          {
            relation_type: 'IsPublishedIn',
            related_identifier: 'http://www.heatflow.und.edu/index2.html',
            resource_type_general: 'OutputManagementPlan',
            related_identifier_type: 'URL'
          },
          {
            relation_type: 'IsReferencedBy',
            related_identifier: 'urn:nbn:de:101:1-201102033592',
            resource_type_general: 'PeerReview',
            related_identifier_type: 'URN'
          },
          {
            relation_type: 'References',
            related_identifier: 'https://w3id.org/games/spec/coil#Coil_Bomb_Die_Of_Age',
            resource_type_general: 'PhysicalObject',
            related_identifier_type: 'w3id'
          },
          {
            relation_type: 'IsDocumentedBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Preprint',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Documents',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Report',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsCompiledBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Service',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Compiles',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Software',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsVariantFormOf',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Sound',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsOriginalFormOf',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Standard',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsIdenticalTo',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Text',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsReviewedBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Workflow',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Reviews',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsDerivedFrom',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsSourceOf',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsRequiredBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Requires',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Obsoletes',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsObsoletedBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'Collects',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          },
          {
            relation_type: 'IsCollectedBy',
            related_identifier: '10.1016/j.epsl.2011.11.037',
            resource_type_general: 'Other',
            related_identifier_type: 'DOI'
          }
        ]
      }
    )
  end
end
