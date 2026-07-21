# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetSuppressQuery do
  let(:dataset_suppress_query) { described_class.new(provider: provider) }

  describe '#suppression_ids' do
    context 'when both query and Settings define ids to suppress' do
      let(:provider) { 'datacite' }

      before do
        allow(Settings.datacite).to receive(:suppress).and_return(['4'])
        DatasetRecord.create!({ id: 1, dataset_id: '1',
                                provider: provider,
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Environmental Molecular Sciences Laboratory' } } } } })

        DatasetRecord.create!({ id: 3, dataset_id: '3',
                                provider: provider,
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Environmental Molecular Sciences Laboratory' } } } } })
        DatasetRecord.create!({ id: 2, dataset_id: '2',
                                provider: provider,
                                source: { data:
                                        { attributes:
                                          { publisher:
                                            { name: 'Shamwow' } } } } })
      end

      it 'returns ids of records that have a specific publisher' do
        expect(dataset_suppress_query.suppression_ids).to contain_exactly(
          '1', '3', '4'
        )
      end
    end

    context 'when settings alone provides ids to suppress' do
      let(:provider) { 'redivis' }

      before do
        allow(Settings.redivis).to receive(:suppress).and_return(%w[5 6])
      end

      it 'returns ids specified in Settings' do
        expect(dataset_suppress_query.suppression_ids).to contain_exactly(
          '5', '6'
        )
      end
    end
  end
end
