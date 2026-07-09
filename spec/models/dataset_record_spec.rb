# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetRecord do
  # Test scope methods
  describe 'scopes' do
    describe '.by_publisher' do
      # Set up record that should be returned
      let(:matching_record) do
        described_class.create!({ id: 1, dataset_id: '1',
                                  provider: 'datacite',
                                  source: { data:
                                          { attributes:
                                            { publisher:
                                              { name: 'Zenodo' } } } } })
      end
      # Set up record that should not be returned
      let(:excluded_record) do
        described_class.create!({ id: 2, dataset_id: '2',
                                  provider: 'datacite',
                                  source: { data:
                                          { attributes:
                                            { publisher:
                                              { name: 'Shamwow' } } } } })
      end

      it 'returns only records with matching publisher name' do
        expect(described_class.by_publisher('Zenodo')).to contain_exactly(matching_record)
      end
    end
  end
end
