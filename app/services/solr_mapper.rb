# frozen_string_literal: true

# Map from Dataworks metadata to Solr metadata
# rubocop:disable Metrics/ClassLength
class SolrMapper
  # Solr field of type text allows up to 32_766 characters
  # but encoding can expand the length, so we are enforcing
  # a smaller length
  TEXT_LIMIT = 32_000
  def self.call(...)
    new(...).call
  end

  # @param metadata [Hash] the Dataworks metadata
  # @param doi [String] the DOI, if present, stored in the dataset record
  def initialize(metadata:, doi:, dataset_record_id:, dataset_record_set_id:)
    @metadata = metadata.with_indifferent_access
    @doi = doi
    @dataset_record_id = dataset_record_id
    @dataset_record_set_id = dataset_record_set_id
  end

  # @return [Hash] the Solr document
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def call
    {
      id: dataset_record_id,
      dataset_record_set_id_ss: dataset_record_set_id,
      access_ssi: metadata['access'],
      provider_ssi: metadata['provider'],
      descriptions_tsim: descriptions_field,
      doi_ssi: doi,
      provider_identifier_ssi: provider_identifier_field,
      creators_ssim: person_or_organization_names_field('creators'),
      creators_ids_sim: person_or_organization_ids_field('creators'),
      contributors_ssim: person_or_organization_names_field('contributors'),
      contributors_ids_sim: person_or_organization_ids_field('contributors'),
      funders_ssim: funders_field,
      funders_ids_sim: funders_ids_field,
      url_ss: metadata['url'],
      related_ids_sim: related_identifiers_field,
      publisher_ssi: publisher_field,
      publisher_id_sim: publisher_id_field,
      publication_year_isi: metadata['publication_year'].to_i,
      subjects_ssim: subjects_field,
      methods_tsim: descriptions_by_type_field(['Methods']),
      other_descriptions_tsim: descriptions_by_type_field(%w[Other SeriesInformation TableOfContents
                                                             TechnicalInfo]),
      language_ssi: metadata['language'],
      sizes_ssm: metadata['sizes'],
      formats_ssim: metadata['formats'],
      version_ss: metadata['version'],
      rights_uris_sim: rights_uris_field,
      affiliation_names_sim: affilation_names_field,
      variables_tsim: metadata['variables'],
      temporal_isim: temporal_field
    }.merge(title_fields).merge(struct_fields).compact_blank
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
    metadata['identifiers'].find { |i| i['identifier_type'] == provider_ref(metadata['provider']) } ['identifier']
  end

  # By default, Solr will throw errors for text fields that are longer than 32,766 characters
  def descriptions_field
    Array(metadata['descriptions']).filter_map do |d|
      d['description'].truncate(TEXT_LIMIT) if d['description_type'].blank? || d['description_type'] == 'Abstract'
    end
  end

  def person_or_organization_ids_field(field)
    Array(metadata[field]).map do |creator|
      creator['name_identifiers']&.pluck('name_identifier')
    end.flatten.compact
  end

  def funders_field
    metadata['funding_references']&.pluck('funder_name')&.compact || []
  end

  def funders_ids_field
    metadata['funding_references']&.pluck('funder_identifier')&.compact || []
  end

  def descriptions_by_type_field(description_types)
    Array(metadata['descriptions']).filter_map do |d|
      next unless description_types.include?(d['description_type'])

      d['description'].truncate(TEXT_LIMIT)
    end
  end

  def rights_uris_field
    metadata['rights_list'].pluck('rights_uri')&.uniq&.compact if metadata['rights_list'].present?
  end

  # Names of organizations affiliated with both contributors and creators of a dataset
  def affilation_names_field
    affiliation_names_for_role('creators').concat(affiliation_names_for_role('contributors')).uniq
  end

  # Extract the year from the date for temporal coverage
  # If the date is a range, store a sequence of years from beginning to end
  def temporal_field
    Array(metadata['dates']).filter_map do |date|
      next unless date['date_type'] == 'Coverage'

      parse_date(date['date'])
    end.flatten
  end

  # Return an array of dates based on the parsing of the date string
  def parse_date(date_value)
    # If this is a range, get the years from beginning to end of the range
    if date_value.include?('/')
      date_range_years(date_value)
    else
      [date_year(date_value)]
    end
  end

  private

  attr_reader :metadata, :doi, :dataset_record_id, :dataset_record_set_id

  # Given titles from metadata, return field value based on title type
  def title_values(title_type, titles)
    titles.filter_map { |title_obj| title_obj['title'] if title_obj['title_type'] == title_type }
  end

  # Get the identifier type associated with a particular provider
  def provider_ref(provider)
    case provider
    when 'DataCite', 'Dryad'
      'DOI'
    when 'Zenodo'
      'ZenodoId'
    else
      "#{provider}Reference"
    end
  end

  def person_or_organization_names_field(field)
    metadata[field]&.pluck('name')
  end

  def struct_fields
    %w[creators contributors dates rights_list funding_references
       related_identifiers].filter_map do |field|
      [:"#{field}_struct_ss", metadata[field]&.to_json]
    end.to_h
  end

  def related_identifiers_field
    metadata['related_identifiers']&.pluck('related_identifier')
  end

  def publisher_id_field
    metadata.dig('publisher', 'publisher_identifier')
  end

  def publisher_field
    metadata.dig('publisher', 'name')
  end

  def subjects_field
    metadata['subjects']&.pluck('subject')
  end

  # A range should be specified as [date]/[date] where date can be in
  # multiple formats. See dataworks_schema.yml for details.
  def date_range_years(date_value)
    return [] unless date_value.split('/').length == 2

    years = date_value.split('/').map do |date_section|
      date_year(date_section)
    end
    # Create range of years including the beginning and end years provided
    Array(years[0]..years[1])
  end

  # Retrieve just the year from a particular date string
  def date_year(date_value)
    # An allowable schema date format is just the year e.g. '2024'
    return date_value.to_i if date_value.length == 4

    # Date.parse will work with both 'YYYY-MM-DD' and 'YYYY- MM-DDThh:mm:ssTZD'
    Date.parse(date_value).year
  end

  # Retrieve affiliation name array given either creator or contributor field
  def affiliation_names_for_role(role)
    Array(metadata[role]).flat_map do |role_entity|
      role_entity['affiliation']&.pluck('name')
    end&.compact
  end
end
# rubocop:enable Metrics/ClassLength
