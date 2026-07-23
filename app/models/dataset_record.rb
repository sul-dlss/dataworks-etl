# frozen_string_literal: true

# Source metadata for a dataset
class DatasetRecord < ApplicationRecord
  has_many :dataset_record_associations, dependent: :destroy
  has_many :dataset_record_sets, through: :dataset_record_associations

  # Don't bother printing the entire source JSON in logs/inspect, as it can
  # slow things down considerably in a console session
  self.filter_attributes = [:source]

  before_save ->(dataset_record) { dataset_record.source_md5 = Digest::MD5.hexdigest(dataset_record.source.to_json) }

  # Adding a scope for suppression by query for publisher in DataCite metadata
  # JSON queries vary by adapter so we are taking that into account
  scope :by_publisher, lambda { |name|
    where(Arel.sql(publisher_query, name))
  }

  # Adding a scope for suppression by query by returning dataset ids that do
  # not correspond to particular identifier prefixes
  # exclude_prefixes: the prefixes we do NOT want the returned list of dataset records to match
  # in their identifiers list
  # The metadata paths are Datacite specific
  scope :by_excluding_prefix, lambda { |exclude_prefixes|
    where('NOT (source @@ ?::jsonpath)', identifier_jsonpath(exclude_prefixes))
  }

  # @return [String] unique identifier for the dataset (independent of the provider)
  def external_dataset_id
    doi || [provider, dataset_id].join('-')
  end

  # @return String query source to be employed based on type of connection
  # Query syntax assumes Postgres
  def self.publisher_query
    "source #>> '{data,attributes,publisher,name}' = ?"
  end

  # @return String query to be executed to return dataset records that
  # do not have identifiers which match any of the prefixes in exclude_prefixes
  # Query syntax assumes Postgres
  def self.identifier_jsonpath(exclude_prefixes)
    # Create the regular expression string for the prefixes using '|' to signify OR
    regex_list = exclude_prefixes.map { |prefix| Regexp.escape(prefix) }.join('|')
    # The following translates into: does there exist identifier values in the
    # identifiers array that starts with any of the prefixes in the 'exclude_prefixes' array
    "exists($.data.attributes.identifiers[*].identifier ? (@ like_regex \"^(#{regex_list})\" ) )"
  end
end
