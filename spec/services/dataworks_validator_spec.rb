# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksValidator do
  subject(:validator) { described_class.new(metadata:) }

  context 'when metadata is valid' do
    let(:metadata) do
      {
        titles: [{ title: 'PRIME India' }]
      }
    end

    it 'returns true for valid?' do
      expect(validator.valid?).to be true
    end

    it 'returns no errors' do
      expect(validator.errors).to be_empty
    end
  end

  context 'when metadata is invalid' do
    let(:metadata) do
      {
        titles: [],
        another_field: 'invalid'
      }
    end

    it 'returns false for valid?' do
      expect(validator.valid?).to be false
    end

    it 'returns errors' do
      expect(validator.errors).to eq(
        [
          'array size at `/titles` is less than: 1',
          'object property at `/another_field` is a disallowed additional property'
        ]
      )
    end
  end
end
