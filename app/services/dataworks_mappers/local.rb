# frozen_string_literal: true

module DataworksMappers
  # Mapper for local datasets
  class Local < Base
    def perform_map
      source
    end
  end
end
