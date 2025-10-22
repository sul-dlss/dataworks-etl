# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#number_from_human_size' do
    it 'converts human-readable sizes to bytes' do
      expect(helper.number_from_human_size('5 MB')).to eq(5 * 1024 * 1024)
      expect(helper.number_from_human_size('1.5 GB')).to eq((1.5 * (1024**3)).to_i)
      expect(helper.number_from_human_size('100 bytes')).to eq(100)
      expect(helper.number_from_human_size('2 TB')).to eq(2 * (1024**4))
      expect(helper.number_from_human_size('500 kb')).to eq(500 * 1024)
      expect(helper.number_from_human_size('250 b')).to eq(250)
      expect(helper.number_from_human_size('1')).to eq(1)
    end

    it 'handles edge cases and invalid inputs' do
      expect(helper.number_from_human_size('invalid')).to be_nil
      expect(helper.number_from_human_size('123 unknown')).to be_nil
      expect(helper.number_from_human_size(nil)).to be_nil
      expect(helper.number_from_human_size(123)).to be_nil
      expect(helper.number_from_human_size('')).to be_nil
    end

    it 'is case insensitive for units' do
      expect(helper.number_from_human_size('5 mb')).to eq(5 * 1024 * 1024)
      expect(helper.number_from_human_size('1.5 Gb')).to eq((1.5 * (1024**3)).to_i)
      expect(helper.number_from_human_size('100 BYTES')).to eq(100)
    end
  end

  describe '#mime_type_friendly_name' do
    it 'uses translation lookup for MIME types we know' do
      expect(helper.mime_type_friendly_name('application/x-stata')).to eq('Stata')
    end

    it 'returns friendly names for other known MIME types where possible' do
      expect(helper.mime_type_friendly_name('image/jpeg')).to eq('JPEG Image')
    end

    it 'returns nil for unknown MIME types' do
      expect(helper.mime_type_friendly_name('application/unknown')).to be_nil
    end

    it 'returns nil for things that are not MIME types' do
      expect(helper.mime_type_friendly_name('csv')).to be_nil
    end
  end
end
