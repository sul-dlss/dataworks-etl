# frozen_string_literal: true

module Extractors
  # Service for extracting datasets from Dryad
  class Dryad < ClientBase
    def initialize(affiliation: 'https://ror.org/00f54p054')
      super(
        client: Clients::Dryad.new, provider: 'dryad',
        list_args: { affiliation: }, extract_sleep: Settings.dryad_extract_sleep
        )
    end

    private

    def doi_from(source:)
      source['identifier'].delete_prefix('doi:')
    end
  end
end
