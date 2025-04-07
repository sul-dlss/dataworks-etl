# frozen_string_literal: true

module DataworksMappers
  # Map from Redivis metadata to Dataworks metadata
  class Redivis < Base
    def perform_map
      {
        titles: [{ title: source[:name] }]
      }
    end
  end
end
