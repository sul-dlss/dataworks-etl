# frozen_string_literal: true

# Suppresses particular datasets based on queries and providers.
#
# The public entry point is +suppression_ids_by_provider+, which builds the full
# provider => ids map in one pass (computed once per load by TransformerLoader and
# passed to DatasetTransformer, so the suppression queries do not run per dataset).
class DatasetSuppressQuery
  DATACITE_PUBLISHER = 'Environmental Molecular Sciences Laboratory'

  # @param providers [Array<String>] providers to build suppression ids for
  # @return [Hash{String => Array<String>}] map of provider to suppressed dataset ids
  def self.suppression_ids_by_provider(providers:)
    providers.index_with { |provider| suppression_ids(provider:).compact }
  end

  # @param provider [String] the provider to gather suppressed ids for
  # @return [Array<String>] suppressed dataset ids for the provider
  def self.suppression_ids(provider:)
    ids = suppress_by_settings(provider:).dup
    ids.concat(suppress_datacite_by_query(provider:)) if provider == 'datacite'

    ids
  end

  def self.suppress_by_settings(provider:)
    Settings[provider]&.suppress || []
  end

  # Returns ids to be suppressed based on a particular query
  def self.suppress_datacite_by_query(provider:)
    DatasetRecord.where(provider:).by_publisher(DATACITE_PUBLISHER).pluck(:dataset_id)
  end

  private_class_method :suppression_ids, :suppress_by_settings, :suppress_datacite_by_query
end
