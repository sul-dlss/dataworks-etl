# frozen_string_literal: true

# Map from Dataworks metadata to Vertex AI metadata
class VertexMapper
  TITLE_TYPES = [nil, 'Subtitle', 'AlternativeTitle', 'TranslatedTitle', 'Other'].freeze

  def self.call(...)
    new(...).call
  end

  # @param metadata [Hash] the Dataworks metadata
  # @param doi [String] the DOI, if present, stored in the dataset record
  # @param id [String] the ID of the dataset
  # @param load_id [String] the ID of the load
  # @param provider_identifiers_map [Hash<String,String>] a map of provider identifiers to their values
  def initialize(metadata:, doi:, id:, load_id:, provider_identifiers_map:)
    @metadata = metadata.with_indifferent_access
    @doi = doi
    @id = id
    @load_id = load_id
    @provider_identifiers_map = provider_identifiers_map
  end

  # @return [Hash] the Solr document
  def call # rubocop:disable Metrics/AbcSize
    {
      id:,
      access: metadata['access'],
      provider: metadata['provider'],
      description: description_field,
      other_descriptions: other_descriptions_field,
      doi:,
      title: titles.first.truncate(1000),
      other_titles: titles[1..],
      provider_identifier: provider_identifier_field,
      contributors: contributors_field,
      contributors_ids: contributors_ids_field,
      url: metadata['url'],
      subjects: subjects_field,
      text: text_field
    }.compact_blank
  end

  private

  attr_reader :metadata, :doi, :id, :load_id, :provider_identifiers_map

  def titles
    # SolrMappers::Titles.call(metadata:)
    @titles ||= metadata['titles'].sort_by do |title|
      TITLE_TYPES.index(title['title_type'])
    end.pluck('title')
  end

  # Retrieve the identifier used by the provider themselves
  def provider_identifier_field
    metadata['identifiers'].find { |i| i['identifier_type'] == provider_ref(metadata['provider']) } ['identifier']
  end

  def description_field
    abstracts.first&.[]('description')
  end

  def abstracts
    Array(metadata['descriptions']).select { |description| abstract?(description) }
  end

  def other_descriptions_field
    other_descriptions = Array(metadata['descriptions']).reject do |description|
      abstract?(description)
    end
    (Array(abstracts[1..]) + other_descriptions).pluck('description')
  end

  def abstract?(description)
    description['description_type'].blank? || description['description_type'] == 'Abstract'
  end

  # Get the identifier type associated with a particular provider
  def provider_ref(provider)
    case provider
    when 'DataCite', 'Dryad'
      'DOI'
    when 'Zenodo'
      'ZenodoId'
    when 'SDR'
      'DRUID'
    else
      "#{provider}Reference"
    end
  end

  def contributors
    @contributors ||= (Array(metadata['creators']) + Array(metadata['contributors']))
  end

  def contributors_field
    contributors.pluck('name').compact
  end

  def contributors_ids_field
    contributors.pluck('name_identifiers').flatten.compact.pluck('name_identifier').compact
  end

  def subjects_field
    metadata['subjects']&.pluck('subject')
  end

  def text_field
    text_from(metadata).flatten.compact.uniq.join(' ')
  end

  def text_from(obj)
    return text_from(obj.values) if obj.is_a?(Hash)
    return obj.map { |obj_value| text_from(obj_value) } if obj.is_a?(Array)

    obj&.to_s
  end
end
