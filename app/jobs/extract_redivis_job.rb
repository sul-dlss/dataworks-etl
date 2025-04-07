# frozen_string_literal: true

# Job to extract dataset metadata from Redivis
class ExtractRedivisJob < ExtractJob
  def perform(organization:)
    Extractors::Redivis.call(organization:)
  end
end
