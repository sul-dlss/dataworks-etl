# frozen_string_literal: true

FactoryBot.define do
  factory :dataset_record do
    provider { 'redivis' }
    sequence(:dataset_id) { |n| "abc#{n}" }
    modified_token { '1.2.3' }
    sequence(:doi) { |n| "doi:10.0000/#{provider}.abc#{n}" }
    source_md5 { Digest::MD5.hexdigest(source.to_json) }
    sequence(:source) do |n|
      {
        name: "My dataset #{n}",
        owner: { fullName: 'Test Owner' },
        version: { tag: "v0.#{n}" },
        doi:,
        createdAt: 1_574_457_099_929, # Milliseconds since epoch
        url: "https://example.com/#{doi}",
        description: 'This is an abstract for the example dataset.',
        qualifiedReference: 'stanfordphs.prime_india:016c:v0_1',
        tables: [{ variables: [{ name: 'geometry', label: nil }] }]
      }
    end
    created_at { Time.current }
    updated_at { Time.current }

    trait :datacite do
      provider { 'datacite' }
      dataset_id { doi }
      sequence(:source) do |n|
        {
          data: {
            id: doi,
            type: 'dois',
            attributes: {
              doi: doi,
              creators: [
                {
                  name: 'ExampleFamilyName, ExampleGivenName', nameType: 'Personal',
                  givenName: 'ExampleGivenName', familyName: 'ExampleFamilyName'
                }
              ],
              contributors: [],
              titles: [{ lang: 'en', title: "My datacite dataset #{n}" }],
              container: {
                type: 'DataRepository',
                title: 'Example SeriesInformation',
                identifier: 'http://purl.oclc.org/foo/bar',
                identifierType: 'PURL'
              },
              publicationYear: 2023,
              subjects: [],
              version: '1',
              descriptions: [
                {
                  lang: 'en', description: 'This is an abstract for the example datacite dataset.',
                  descriptionType: 'Abstract'
                }
              ],
              dates: [],
              identifiers: [],
              relatedIdentifiers: [],
              rightsList: [],
              fundingReferences: [],
              url: "https://example.com/#{doi}",
              created: '2022-10-27T19:09:17.000Z',
              registered: '2022-10-27T19:15:48.000Z',
              published: '2023',
              updated: '2024-02-26T20:19:26.000Z'
            }
          }
        }
      end
    end
  end
end
