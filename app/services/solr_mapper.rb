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
      provider_identifier_ssim: metadata['identifiers'].pluck('identifier'),
      creators_struct_ss: metadata['creators'].to_json
    }.merge(map_titles(metadata['titles']))
  end

  private

  attr_reader :metadata, :dataset_record_id, :dataset_record_set_id

  # Given titles from metadata, return field value based on title type
  def title_fields(title_type, titles)
    titles.select { |title_obj| title_obj.key?('title_type') && title_obj['title_type'] == title_type }.pluck('title')
  end

  def map_titles(titles_metadata)
    titles = titles_metadata.reject { |title_obj| title_obj.key?('title_type') }.pluck('title')
    subtitles = title_fields('Subtitle', titles_metadata)
    alternative_titles = title_fields('AlternativeTitle', titles_metadata)
    translated_titles =  title_fields('TranslatedTitle', titles_metadata)
    other_titles = title_fields('Other', titles_metadata)

    titles = assign_titles(titles, subtitles, alternative_titles, translated_titles, other_titles)

    map_typed_title_fields(titles, subtitles, alternative_titles, translated_titles, other_titles)
  end

  def assign_titles(titles, subtitles, alternative_titles, translated_titles, other_titles)
    # One of the title elements is required, but we will use one of the other titles when present
    return titles unless titles.empty?

    if !alternative_titles.empty?
      alternative_titles
    elsif !subtitles.empty?
      subtitles
    elsif !other_titles.empty?
      other_titles
    else
      translated_titles
    end
  end

  def map_typed_title_fields(titles, subtitles, alternative_titles, translated_titles, other_titles)
    mapped_titles = {
      title_tsim: titles
    }
    mapped_titles[:subtitle_tsim] = subtitles unless subtitles.empty?
    mapped_titles[:alternative_title_tsim] = alternative_titles unless alternative_titles.empty?
    mapped_titles[:translate_title_tsim] = translated_titles unless translated_titles.empty?
    mapped_titles[:other_title_tsim] = other_titles unless other_titles.empty?
    mapped_titles
  end
end
