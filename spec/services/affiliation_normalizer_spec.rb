# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AffiliationNormalizer do
  subject(:normalized) { described_class.call(mapped_record:) }

  def affiliations_for(field)
    normalized[field].flat_map { |entry| entry['affiliation'] }
  end

  context 'with a semicolon-delimited affiliation name and no identifier' do
    let(:name) { 'Institute of Geography, Heidelberg University; HeiGIT at Heidelberg University' }
    let(:mapped_record) do
      { creators: [{ name: 'Smith, Jane', affiliation: [{ 'name' => name }] }] }
    end

    it 'splits it into one affiliation per institution' do
      expect(affiliations_for(:creators)).to eq(
        [{ 'name' => 'Institute of Geography, Heidelberg University' },
         { 'name' => 'HeiGIT at Heidelberg University' }]
      )
    end
  end

  context 'with a semicolon-delimited name that carries an identifier' do
    let(:mapped_record) do
      {
        creators: [{ name: 'Smith, Jane',
                     affiliation: [{ 'name' => 'The University of Texas at Austin; Marine Science Institute',
                                     'affiliation_identifier' => 'https://ror.org/00hj54h04',
                                     'affiliation_identifier_scheme' => 'ROR' }] }]
      }
    end

    it 'leaves it intact so the identifier is not mis-attached' do
      expect(affiliations_for(:creators)).to eq(
        [{ 'name' => 'The University of Texas at Austin; Marine Science Institute',
           'affiliation_identifier' => 'https://ror.org/00hj54h04',
           'affiliation_identifier_scheme' => 'ROR' }]
      )
    end
  end

  context 'when a semicolon appears only inside an HTML entity' do
    let(:mapped_record) do
      { creators: [{ name: 'Smith, Jane', affiliation: [{ 'name' => 'King&apos;s College London' }] }] }
    end

    it 'decodes the entity without splitting' do
      expect(affiliations_for(:creators)).to eq([{ 'name' => "King's College London" }])
    end
  end

  context 'with markup in an affiliation name' do
    let(:mapped_record) do
      { contributors: [{ name: 'Lal, Apoorva', affiliation: [{ 'name' => 'Ecology &amp; Evolution' }] }] }
    end

    it 'strips markup while keeping ampersands' do
      expect(affiliations_for(:contributors)).to eq([{ 'name' => 'Ecology & Evolution' }])
    end
  end

  context 'with three institutions in one name' do
    let(:name) do
      'Heidelberg University; Harvard T.H. Chan School of Public Health; Africa Health Research Institute'
    end
    let(:mapped_record) do
      { creators: [{ name: 'Smith, Jane', affiliation: [{ 'name' => name }] }] }
    end

    it 'splits on every delimiter and trims whitespace' do
      expect(affiliations_for(:creators).pluck('name')).to eq(
        ['Heidelberg University', 'Harvard T.H. Chan School of Public Health', 'Africa Health Research Institute']
      )
    end
  end

  context 'when a creator has no affiliation' do
    let(:mapped_record) { { creators: [{ name: 'Smith, Jane' }] } }

    it 'returns the creator unchanged' do
      expect(normalized[:creators]).to eq([{ 'name' => 'Smith, Jane' }])
    end
  end

  it 'leaves other person attributes intact' do
    creator = described_class.call(
      mapped_record: { creators: [{ name: 'Smith, Jane', name_type: 'Personal',
                                    affiliation: [{ 'name' => 'Stanford University' }] }] }
    )[:creators].first
    expect(creator[:name]).to eq('Smith, Jane')
    expect(creator[:name_type]).to eq('Personal')
    expect(creator[:affiliation]).to eq([{ 'name' => 'Stanford University' }])
  end
end
