# frozen_string_literal: true

# Map from Dataworks metadata to Solr metadata
class SolrMapper
  def self.call(...)
    new(...).call
  end

  # @param metadata [Hash] the Dataworks metadata
  def initialize(metadata:, dataset_record_id:, dataset_record_set_id:)
    @metadata = metadata.with_indifferent_access
    @dataset_record_id = dataset_record_id
    @dataset_record_set_id = dataset_record_set_id
  end

  # @return [Hash] the Solr document
  def call
    {
      id: dataset_record_id,
      dataset_record_set_id_ss: dataset_record_set_id,
      access_ssi: metadata['access'],
      provider_ssi: metadata['provider'],
      creators_struct_ss: metadata['creators'].to_json,
      descriptions_tsim: descriptions_field,
      doi_ssi: doi_field,
      provider_identifier_ssi: provider_identifier_field
    }.merge(title_fields).compact_blank
  end

  # rubocop:disable Metrics/AbcSize
  def title_fields
    titles = metadata['titles'].reject { |title_obj| title_obj.key?('title_type') }.pluck('title')
    subtitles = title_values('Subtitle', metadata['titles'])
    alternative_titles = title_values('AlternativeTitle', metadata['titles'])
    translated_titles =  title_values('TranslatedTitle', metadata['titles'])
    other_titles = title_values('Other', metadata['titles'])

    # The schema requires that a title of any type be present
    # The Solr mapping requires a dedicated title field, so this ensures
    # the main title field is populated
    primary_title = titles.presence || subtitles.presence || alternative_titles.presence ||
                    translated_titles.presence || other_titles

    {
      title_tsim: primary_title,
      subtitle_tsim: subtitles,
      alternative_title_tsim: alternative_titles,
      translate_title_tsim: translated_titles,
      other_title_tsim: other_titles
    }.compact_blank
  end
  # rubocop:enable Metrics/AbcSize

  # Retrieve the identifier used by the provider themselves
  def provider_identifier_field
    metadata['identifiers'].filter_map do |id_info|
      id_info['identifier'] if id_info['identifier_type'] == provider_ref(metadata['provider'])
    end.first
  end

  # Not every dataset will have a DOI provided
  def doi_field
    metadata['identifiers'].filter_map do |id_info|
      id_info['identifier'] if id_info['identifier_type'] == 'DOI'
    end.first || ''
  end

  # By default, Solr will throw errors for text fields that are longer than 32,766 characters
  def descriptions_field
    metadata['descriptions']&.filter_map do |d|
      d['description'].truncate(32_766) if d['description_type'].blank? || d['description_type'] == 'Abstract'
    end || []
  end

  private

  attr_reader :metadata, :dataset_record_id, :dataset_record_set_id

  # Given titles from metadata, return field value based on title type
  def title_values(title_type, titles)
    titles.filter_map { |title_obj| title_obj['title'] if title_obj['title_type'] == title_type }
  end

  # Get the identifier type associated with a particular provider
  def provider_ref(provider)
    case provider
    when 'DataCite'
      'DOI'
    when 'Zenodo'
      'ZenodoId'
    else
      "#{provider}Reference"
    end
  end
end
