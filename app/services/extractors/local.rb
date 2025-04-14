# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from local YAML files
  class Local < Base
    def initialize(path: 'config/local_datasets')
      super(
        client: LocalReader.new(path:),
        provider: 'local'
        )
    end

    private

    def doi_from(source:)
      source['identifiers'].find { |identifier| identifier['identifier_type'] == 'DOI' }&.fetch('identifier')
    end

    # Reads local YAML files and returns a list of datasets
    # This acts like a client.
    class LocalReader
      def initialize(path:)
        @path = path
      end

      def list
        Dir.glob("#{path}/*.yml").map do |filepath|
          metadata = YAML.load_file(filepath)
          DataworksValidator.new(metadata:).valid!
          Clients::ListResult.new(
            id: File.basename(filepath, '.yml'),
            modified_token: Digest::MD5.hexdigest(metadata.to_json),
            source: metadata
          )
        end
      end

      private

      attr_reader :path
    end
  end
end
