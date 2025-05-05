# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DateParsing do
  describe '.parse_date_range' do
    context 'when given a valid date range string' do
      it 'returns an array of years in the range' do
        expect(described_class.parse_date_range('2023-01-01/2025-12-31')).to eq([2023, 2024, 2025])
      end
    end

    context 'when given an invalid date range string' do
      it 'returns nil' do
        expect(described_class.parse_date_range('invalid-range')).to be_nil
      end
    end

    context 'when given a blank string' do
      it 'returns nil' do
        expect(described_class.parse_date_range('')).to be_nil
      end
    end

    context 'when the date range string has invalid dates' do
      it 'returns nil' do
        expect(described_class.parse_date_range('2023-01-01/invalid-date')).to be_nil
      end
    end
  end
end
