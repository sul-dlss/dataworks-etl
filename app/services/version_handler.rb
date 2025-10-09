# frozen_string_literal: true

# Removes previous versions of canonical or more recent DOIs we have retrieved
class VersionHandler
  def initialize(solr_docs:)
    @solr_docs = solr_docs
    @dois_set = extract_dois
  end

  def removal_dois_set
    remove_relation_dois = remove_by_relation_types
    # Remove the DOIs based on relation type parsing
    modified_dois_set = @dois_set.subtract(remove_relation_dois)
    # Based on the new set of DOIs, remove versions based on DOI version suffixes
    remove_number_dois = remove_by_version_number(modified_dois_set.to_a)
    # This is the set of all DOIs to remove
    Set.new(remove_relation_dois.concat(remove_number_dois).uniq)
  end

  def extract_dois
    dois = @solr_docs.select { |doc| doc.key?('doi_ssi') }.pluck('doi_ssi')
    Set.new(dois)
  end

  # Retrieve which DOIs need to be removed based on relation types
  def remove_by_relation_types
    # Array of dois we will be removing
    remove_dois = []
    @solr_docs.each do |solr_doc|
      doi = solr_doc['doi_ssi']
      related_id_struct = solr_doc['related_identifiers_struct_ss']

      next unless doi.present? && related_id_struct.present?

      JSON.parse(related_id_struct).each do |related_info|
        remove_dois.concat(process_relation_types(doi, related_info))
      end
    end

    remove_dois
  end

  def process_relation_types(doi, related_info)
    remove_dois = []
    related_id = related_info['related_identifier']
    relation_type = related_info['relation_type']

    next unless relation_type.present? && @dois_set.include?(related_id)

    remove_dois << doi if %w[IsPreviousVersionOf IsVersionOf].include?(relation_type)
    remove_dois << related_id if %w[IsNewVersionOf HasVersion].include?(relation_type)
    remove_dois
  end

  def remove_by_version_number(modified_dois)
    remove_dois = []

    prefix_hash = generate_prefix_hash(modified_dois)
    prefix_hash.each do |k, v|
      next unless v.length > 1

      if v.include?('')
        # Keep the base DOI without any version info as that is probably the canonical
        # version and will link to other versions
        remove_these = v.reject { |version| version == '' }.map { |version| "#{k}.#{version}" }
      else
        sorted_v = v.sort
        # Keep only the biggest version i.e. the last element of the sorted array
        remove_these = sorted_v[0, sorted_v.length - 1].map { |version| "#{k}.#{version}" }
      end
      remove_dois.concat(remove_these)
    end
    remove_dois
  end

  def generate_prefix_hash(modified_dois)
    prefix_hash = {}
    modified_dois.sort.each do |d|
      prefix = d
      version = ''
      if /\w+\.\w+\.v[\d+][.\d]*$/.match?(d)
        prefix = d[0, d.rindex('.v')]
        version = d[d.rindex('.v') + 1, d.length]
      end

      prefix_hash[prefix] = [] unless prefix_hash.key?(prefix)
      prefix_hash[prefix] << version
    end
    prefix_hash
  end
end
