# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Base do
  let(:test_mapper) do
    Class.new(described_class) do
      def perform_map
        {}
      end
    end
  end

  it 'raises an error when it maps to invalid dataworks metadata' do
    expect { test_mapper.new(source: {}).call }.to raise_error(DataworksMappers::MappingError)
  end
end
