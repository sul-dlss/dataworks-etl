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
  # @param id [String] the ID of the dataset
  # @param load_id [String] the ID of the load
  def initialize(metadata:, doi:, id:, load_id:)
    @metadata = metadata.with_indifferent_access
    @doi = doi
    @id = id
    @load_id = load_id
  end

  # @return [Hash] the Solr document
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def call
    {
      id:,
      load_id_ssi: load_id,
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

  def title_fields
    SolrMappers::Titles.call(metadata:)
  end

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

      if date['date'].include?('/')
        DateParsing.parse_date_range(date['date'])
      else
        Date.edtf(date['date'])&.year
      end
    end.flatten
  end

  private

  attr_reader :metadata, :doi, :id, :load_id

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

  # Retrieve affiliation name array given either creator or contributor field
  def affiliation_names_for_role(role)
    Array(metadata[role]).flat_map do |role_entity|
      role_entity['affiliation']&.pluck('name')
    end&.compact
  end
end
# rubocop:enable Metrics/ClassLength
