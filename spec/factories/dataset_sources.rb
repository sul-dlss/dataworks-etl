# frozen_string_literal: true

FactoryBot.define do
  factory :dataset_source do
    provider { 'redivis' }
    sequence(:dataset_id) { |n| "abc#{n}" }
    modified_token { '1.2.3' }
    sequence(:doi) { |n| "doi:10.0000/redivis.abc#{n}" }
    source_md5 { Digest::MD5.hexdigest(source.to_json) }
    source { { title: 'My dataset' }.to_json }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
