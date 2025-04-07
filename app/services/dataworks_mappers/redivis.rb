# frozen_string_literal: true

module DataworksMappers
  # Map from Redivis metadata to Dataworks metadata
  class Redivis
    def self.call(...)
      new(...).call
    end

    # @param source [Hash] the Redivis metadata
    def initialize(source:)
      @source = source.with_indifferent_access
    end

    # @return [Hash] the Dataworks metadata
    def call
      {
        titles: [{ title: source[:name] }]
      }
    end

    private

    attr_reader :source
  end
end
