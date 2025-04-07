# frozen_string_literal: true

module DataworksMappers
  # Base class for mapping from source metadata to Dataworks metadata
  class Base
    def self.call(...)
      new(...).call
    end

    # @param source [Hash] the source metadata
    def initialize(source:)
      @source = source.with_indifferent_access
    end

    # @return [Hash] the Dataworks metadata
    def call
      perform_map.tap do |metadata|
        validate!(metadata:)
      end
    end

    private

    attr_reader :source

    def perform_map
      raise NotImplementedError
    end

    def validate!(metadata:)
      validator = DataworksValidator.new(metadata:)
      return if validator.valid?

      raise MappingError, "Mapping failed: #{validator.errors.join(', ')}"
    end
  end
end
