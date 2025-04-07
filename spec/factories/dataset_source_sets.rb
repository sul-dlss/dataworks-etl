# frozen_string_literal: true

FactoryBot.define do
  factory :dataset_source_set do
    provider { 'redivis' }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
