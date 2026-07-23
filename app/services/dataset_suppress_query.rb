# frozen_string_literal: true

# Suppresses particular datasets based on queries and providers.
#
# The public entry point is +suppression_ids_by_provider+, which builds the full
# provider => ids map in one pass (computed once per load by TransformerLoader and
# passed to DatasetTransformer, so the suppression queries do not run per dataset).
class DatasetSuppressQuery
  EMSL_PUBLISHER = 'Environmental Molecular Sciences Laboratory'
  REDIVIS_PUBLISHER = 'Redivis'
  # Identifier prefixes we wish to keep for sul, phsdata, pulse (Doerr), sdss_data_repository (Doerr)

  REDIVIS_PREFIXES = ['sul.', 'phsdata.', 'sdss_data_repository.', 'pulse.'].freeze

  # @param providers [Array<String>] providers to build suppression ids for
  # @return [Hash{String => Array<String>}] map of provider to suppressed dataset ids
  def self.suppression_ids_by_provider(providers:)
    providers.index_with { |provider| suppression_ids(provider:).compact }
  end

  # @param provider [String] the provider to gather suppressed ids for
  # @return [Array<String>] suppressed dataset ids for the provider
  def self.suppression_ids(provider:)
    ids = suppress_by_settings(provider:).dup
    if provider == 'datacite'
      ids.concat(suppress_by_publisher_query(provider:))
         .concat(suppress_by_identifier_query(provider:))
    end

    ids.uniq
  end

  def self.suppress_by_settings(provider:)
    Settings[provider]&.suppress || []
  end

  # Returns ids to be suppressed based on a query for publisher
  # Specific to Datacite as provider
  def self.suppress_by_publisher_query(provider:)
    DatasetRecord.where(provider:).by_publisher(EMSL_PUBLISHER).pluck(:dataset_id)
  end

  # Returns ids to be suppressed based on Redivis identifier
  # Specific to Datacite as provider and Redivis as publisher
  def self.suppress_by_identifier_query(provider:)
    DatasetRecord.where(provider:).by_publisher(REDIVIS_PUBLISHER)
                 .by_excluding_prefix(REDIVIS_PREFIXES).pluck(:dataset_id)
  end

  private_class_method :suppression_ids, :suppress_by_settings, :suppress_by_publisher_query,
                       :suppress_by_identifier_query
end
