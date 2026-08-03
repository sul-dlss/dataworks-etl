# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RialtoAuthorRefresh do
  let(:config) do
    double('rialto config', file_path: 'spec/fixtures/rialto_data/authors.csv') # rubocop:disable RSpec/VerifiedDoubles
  end

  it 'returns the number of authors loaded' do
    expect(described_class.call(config:)).to eq(3)
  end

  it 'replaces the existing authors with those from the CSV' do
    StanfordAuthor.create!(sunet_id: 'stale', full_name: 'Stale Person')

    described_class.call(config:)

    expect(StanfordAuthor.pluck(:sunet_id)).to match_array(%w[jsmith bwong tlee])
  end

  context 'when loading fails partway through' do
    before { allow(StanfordAuthorLoader).to receive(:call).and_raise(StandardError, 'boom') }

    it 'rolls back so the previously loaded authors are preserved' do
      StanfordAuthor.create!(sunet_id: 'keep', full_name: 'Keep Person')

      expect { described_class.call(config:) }.to raise_error('boom')
      expect(StanfordAuthor.pluck(:sunet_id)).to eq(['keep'])
    end
  end
end
