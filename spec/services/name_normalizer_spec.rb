# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NameNormalizer do
  subject(:normalized) { described_class.call(mapped_record:) }

  context 'with markup in creator and contributor names' do
    let(:mapped_record) do
      {
        creators: [{ name: '&lt;i&gt;Political Analysis&lt;/i&gt;' }, { name: '<b>Smith</b>, Jane' }],
        contributors: [{ name: 'Ecology &amp; Evolution' }, { name: 'Lal, Apoorva' }]
      }
    end

    it 'strips markup from creator names' do
      expect(normalized[:creators].pluck(:name)).to eq(['Political Analysis', 'Smith, Jane'])
    end

    it 'strips markup from contributor names while keeping ampersands' do
      expect(normalized[:contributors].pluck(:name)).to eq(['Ecology & Evolution', 'Lal, Apoorva'])
    end
  end

  context 'when a name is nothing but markup' do
    let(:mapped_record) { { creators: [{ name: '<i></i>' }, { name: 'Real Name' }] } }

    it 'nils the emptied name so it drops from the flat name field downstream' do
      expect(normalized[:creators].pluck(:name)).to eq([nil, 'Real Name'])
    end
  end

  context 'when creators and contributors are absent' do
    let(:mapped_record) { { titles: [{ title: 'A title' }] } }

    it 'returns the record unchanged' do
      expect(normalized[:titles]).to eq([{ 'title' => 'A title' }])
    end
  end

  it 'leaves other person attributes intact' do
    creator = described_class.call(
      mapped_record: { creators: [{ name: '<i>Genus</i>', name_type: 'Personal',
                                    affiliation: [{ name: 'Stanford University' }] }] }
    )[:creators].first
    expect(creator[:name]).to eq('Genus')
    expect(creator[:name_type]).to eq('Personal')
    expect(creator[:affiliation]).to eq([{ 'name' => 'Stanford University' }])
  end
end
