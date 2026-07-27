# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetSuppressQuery do
  describe '.suppression_ids_by_provider' do
    context 'when a provider has both query and Settings ids to suppress' do
      before do
        allow(Settings.datacite).to receive(:suppress).and_return(['4'])
        DatasetRecord.create!({ dataset_id: '1',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Environmental Molecular Sciences Laboratory' } } } } })
        DatasetRecord.create!({ dataset_id: '3',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Environmental Molecular Sciences Laboratory' } } } } })
        DatasetRecord.create!({ dataset_id: '2',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Shamwow' } } } } })
        # This dataset should be returned for suppression b/c of Redivis identifier
        DatasetRecord.create!({ dataset_id: '5',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          {
                                            publisher: { name: 'Redivis' },
                                            identifiers: [{ identifier: 'levante.xyz' }]
                                          } } } })
        # This dataset should not be returned as the identifier is allowed
        DatasetRecord.create!({ dataset_id: '6',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          {
                                            publisher: { name: 'Redivis' },
                                            identifiers: [{ identifier: 'sul.xyz' }]
                                          } } } })
        # This dataset id should be returned b/c it was for
        # Datacite provider, Redivis publisher, and has
        # no identifiers within the metadata
        DatasetRecord.create!({ dataset_id: '7',
                                provider: 'datacite',
                                source: { data:
                                        { attributes:
                                          {
                                            publisher: { name: 'Redivis' },
                                            identifiers: []
                                          } } } })
      end

      it 'merges query and Settings ids for that provider' do
        result = described_class.suppression_ids_by_provider(providers: ['datacite'])

        expect(result['datacite']).to contain_exactly('1', '3', '4', '5', '7')
      end
    end

    context 'when a provider has only Settings ids to suppress' do
      before do
        allow(Settings.redivis).to receive(:suppress).and_return(%w[5 6])
      end

      it 'returns the Settings ids for that provider' do
        result = described_class.suppression_ids_by_provider(providers: ['redivis'])

        expect(result['redivis']).to contain_exactly('5', '6')
      end
    end

    it 'builds an entry for every provider requested' do
      allow(Settings.datacite).to receive(:suppress).and_return(['4'])
      allow(Settings.redivis).to receive(:suppress).and_return(%w[5 6])

      result = described_class.suppression_ids_by_provider(providers: %w[datacite redivis])

      expect(result.keys).to contain_exactly('datacite', 'redivis')
    end
  end
end
