# frozen_string_literal: true

# Suppresses particular datasets based on queries and providers
class DatasetSuppressQuery
  DATACITE_PUBLISHER = 'Environmental Molecular Sciences Laboratory'

  def initialize(provider:)
    @provider = provider
  end

  def suppression_ids
    ids = suppress_by_settings
    ids.concat(suppress_datacite_by_query) if @provider == 'datacite'

    ids
  end

  private

  def suppress_by_settings
    Settings[@provider]&.suppress || []
  end

  # Returns ids to be suppressed based on a particular query
  def suppress_datacite_by_query
    DatasetRecord.where(provider: @provider).by_publisher(DATACITE_PUBLISHER).pluck(:dataset_id)
  end
end
