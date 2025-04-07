# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Redivis do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/redivis.json')) }

  it 'maps to Redivis metadata' do
    expect(metadata).to eq(
      {
        titles: [{ title: 'PRIME India' }]
      }
    )
  end
end
