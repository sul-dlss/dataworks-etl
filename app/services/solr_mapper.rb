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
  # rubocop:disable Metrics/AbcSize
  def call
    {
      id: dataset_record_id,
      dataset_record_set_id_ss: dataset_record_set_id,
      access_ssi: metadata['access'],
      provider_ssi: metadata['provider'],
      creators_struct_ss: metadata['creators'].to_json,
      descriptions_tsim: retrieve_descriptions(metadata['descriptions'] || []),
      doi_ssi: retrieve_doi(metadata['identifiers']) || '',
      provider_identifier_ssim: map_provider_identifiers(metadata['identifiers'], metadata['provider'])
    }.merge(map_titles(metadata['titles']))
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :metadata, :dataset_record_id, :dataset_record_set_id

  # Given titles from metadata, return field value based on title type
  def title_fields(title_type, titles)
    titles.select { |title_obj| title_obj['title_type'] == title_type }.pluck('title')
  end

  def map_titles(titles_metadata)
    titles = titles_metadata.reject { |title_obj| title_obj.key?('title_type') }.pluck('title')
    subtitles = title_fields('Subtitle', titles_metadata)
    alternative_titles = title_fields('AlternativeTitle', titles_metadata)
    translated_titles =  title_fields('TranslatedTitle', titles_metadata)
    other_titles = title_fields('Other', titles_metadata)

    # The schema requires that a title of any type be present
    # The Solr mapping requires a dedicated title field, so this ensures
    # the main title field is populated
    titles = titles.presence || subtitles.presence || alternative_titles.presence ||
             translated_titles.presence || other_titles.presence

    map_typed_title_fields(titles, subtitles, alternative_titles, translated_titles, other_titles)
  end

  def map_typed_title_fields(titles, subtitles, alternative_titles, translated_titles, other_titles)
    # If one of these fields is an empty array, Solr is setup to not add that field
    # so we don't have to check if any of the title arrays or empty or not
    {}.tap do |mapped_titles|
      mapped_titles[:title_tsim] = titles
      mapped_titles[:subtitle_tsim] = subtitles
      mapped_titles[:alternative_title_tsim] = alternative_titles
      mapped_titles[:translate_title_tsim] = translated_titles
      mapped_titles[:other_title_tsim] = other_titles
    end
  end

  def map_provider_identifiers(identifiers_metadata, provider)
    matching_provider_ids(identifiers_metadata, provider).pluck('identifier')
  end

  def matching_provider_ids(identifiers_metadata, provider)
    identifiers_metadata.select { |id_info| id_info['identifier_type'] == provider_ref(provider) }
  end

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

  def retrieve_doi(identifiers_metadata)
    identifiers_metadata.select { |id_info| id_info['identifier_type'] == 'DOI' }.pluck('identifier')[0]
  end

  def retrieve_descriptions(descriptions_metadata)
    descriptions_metadata.select do |description_info|
      !description_info.key?('description_type') ||
        (description_info.key?('description_type') && description_info['description_type'] == 'Abstract')
    end.pluck('description')
  end
end
