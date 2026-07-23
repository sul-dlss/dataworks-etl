# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetRecord do
  # Test scope methods
  describe 'scopes' do
    describe '.by_publisher' do
      before do
        # Set up record that should be returned
        described_class.create!({ dataset_id: '1',
                                  provider: 'datacite',
                                  source: { data:
                                          { attributes:
                                            { publisher:
                                              { name: 'Zenodo' } } } } })
        # Set up record that should not be returned
        described_class.create!({ dataset_id: '2',
                                  provider: 'datacite',
                                  source: { data:
                                          { attributes:
                                            { publisher:
                                              { name: 'Shamwow' } } } } })
      end

      it 'returns only records with matching publisher name' do
        expect(described_class.by_publisher('Zenodo').pluck(:dataset_id)).to contain_exactly('1')
      end
    end

    describe '.by_excluding_prefix' do
      before do
        # Set up records that should have their dataset ids returned by query
        described_class.create!({ dataset_id: '4',
                                  provider: 'datacite',
                                  source: { data:
                                  {
                                    attributes:
                                    {
                                      publisher: { name: 'Redivis' },
                                      identifiers: [{ identifier: 'levante.xyz.110' }]
                                    }
                                  } } })
        described_class.create!({ dataset_id: '5',
                                  provider: 'datacite',
                                  source: { data:
                                  {
                                    attributes:
                                    {
                                      publisher: { name: 'Redivis' },
                                      identifiers: [{ identifier: 'waffle.abc.111' }]
                                    }
                                  } } })
        # This dataset should not be returned as it has the allowed (or excluded from query results) prefix
        described_class.create!({ dataset_id: '7',
                                  provider: 'datacite',
                                  source: { data:
                                  {
                                    attributes:
                                    {
                                      publisher: { name: 'Redivis' },
                                      identifiers: [{ identifier: 'sul.xyz.110' }]
                                    }
                                  } } })
      end

      it 'returns only records that do not match provided prefixes' do
        expect(described_class.by_excluding_prefix(['sul.']).pluck(:dataset_id)).to contain_exactly('4', '5')
      end
    end
  end
end
