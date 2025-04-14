# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Local do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { YAML.load_file('spec/fixtures/local_datasets/example.yml') }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(source.with_indifferent_access)
  end
end
