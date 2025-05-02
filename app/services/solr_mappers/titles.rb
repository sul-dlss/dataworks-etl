# frozen_string_literal: true

module SolrMappers
  # Maps Dataworks metadata to Solr metadata for titles
  class Titles
    def self.call(...)
      new(...).call
    end

    def initialize(metadata:)
      @metadata = metadata.with_indifferent_access
    end

    def call
      # The schema requires that a title of any type be present
      {
        title_tsim: primary_title,
        subtitle_tsim: subtitles,
        alternative_title_tsim: alternative_titles,
        translate_title_tsim: translated_titles,
        other_title_tsim: other_titles
      }.compact_blank
    end

    private

    attr_reader :metadata

    def primary_title
      # The Solr mapping requires a dedicated title field, so this ensures
      # the main title field is populated
      (titles.presence || subtitles.presence || alternative_titles.presence ||
              translated_titles.presence || other_titles)
        .map { |title| title_with_version(title:) }
    end

    def titles
      @titles ||= title_values(title_type: nil)
    end

    def subtitles
      @subtitles ||= title_values(title_type: 'Subtitle')
    end

    def alternative_titles
      @alternative_titles ||= title_values(title_type: 'AlternativeTitle')
    end

    def translated_titles
      @translated_titles ||= title_values(title_type: 'TranslatedTitle')
    end

    def other_titles
      @other_titles ||= title_values(title_type: 'Other')
    end

    # Given titles from metadata, return field values based on title type
    def title_values(title_type:)
      metadata['titles'].filter_map { |title_obj| title_obj['title'] if title_obj['title_type'] == title_type }
    end

    def title_with_version(title:)
      return title unless version

      [title, version].compact.join(' ')
    end

    def version
      @version ||= "V#{metadata['version'].delete_prefix('v').delete_prefix('V')}" if metadata['version'].present?
    end
  end
end
