# frozen_string_literal: true

# Removes previous versions of canonical or more recent DOIs we have retrieved
class VersionHandler
  # @param solr_docs: [hash representing Solr doc]
  def initialize(solr_docs:)
    @solr_docs = solr_docs
    @dois_set = extract_dois
  end

  # Return set of dois to remove from the initializing Solr documents
  def removal_dois_set
    remove_relation_dois = remove_by_relation_types
    # Remove the DOIs based on relation type parsing
    modified_dois_set = @dois_set.subtract(remove_relation_dois)
    # Based on the new set of DOIs, remove versions based on DOI version suffixes
    remove_number_dois = remove_by_version_number(modified_dois_set.to_a)
    # This is the set of all DOIs to remove
    Set.new(remove_relation_dois.concat(remove_number_dois).uniq)
  end

  # Create set of DOIs based on set of Solr documents
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
        remove_doi = compare_versions_for_removal(doi, related_info)
        remove_dois << remove_doi if remove_doi.present?
      end
    end

    remove_dois
  end

  # @param doi: String. DOI of Solr document
  # @param related_info: JSON object representing one of the relationship objects from
  # the 'related_identifiers_struct_ss' in a Solr document
  # Returns which DOI to remove based on the relationship type between the DOI of the Solr document
  # and the related DOI in the related_info JSON object. Returns null if neither DOI is to be removed.
  def compare_versions_for_removal(doi, related_info)
    related_id = related_info['related_identifier']
    relation_type = related_info['relation_type']

    # If no relationship exists or if we don't have the related DOI in our
    # set of Solr documents, then we don't want to remove either of these DOIs.
    return nil unless relation_type.present? && @dois_set.include?(related_id)

    # We want to retain the newest version of a DOI or the canonical version
    # If DOI1 IsPreviousVersionOf DOI2 OR DOI1 IsVersionOf DOI2, we want to remove DOI1
    # If DOI1 IsNewVersionOf DOI2 OR DOI1 HasVersion DOI2, we want to remove DOI2
    return doi if %w[IsPreviousVersionOf IsVersionOf].include?(relation_type)

    related_id if %w[IsNewVersionOf HasVersion].include?(relation_type)
  end

  # @param modified_dois: [String]. Array of DOIs.
  # Returns DOIs to remove based on version suffixes in the DOI strings
  def remove_by_version_number(modified_dois)
    remove_dois = []

    # Get a hash with DOI prefixes as keys and any versions as values
    # or '' representing how the DOI has no version suffixes
    # Example: ['abc.123.v1', 'abc.123.v2', 'abc.123'] should yield
    # {'abc.123' => ['v1','v2','']}
    prefix_hash = generate_prefix_hash(modified_dois)
    prefix_hash.each do |k, v|
      # Without any version suffixes, the value array will still have one element
      # with empty string
      next unless v.length > 1

      # Keep the base DOI without any version info as that is probably the canonical
      # version and will link to other versions
      if v.include?('')
        # Remove everything but the base version.
        # The DOI needs to be rebuilt from prefix and version suffix
        remove_these = v.reject { |version| version == '' }.map { |version| "#{k}.#{version}" }
      else
        # Keep only the biggest version i.e. the last element of the sorted array
        sorted_v = v.sort
        remove_these = sorted_v[0, sorted_v.length - 1].map { |version| "#{k}.#{version}" }
      end
      remove_dois.concat(remove_these)
    end
    remove_dois
  end

  # @param modified_dois: [String]. Array of DOIs.
  # Generate a hash with the part preceding version suffixes as the key and
  # values being an array of version suffixes.  If a DOI has no version suffix,
  # then that DOI's value is represented by an empty string.
  # Example: ['abc.123.v1', 'abc.123.v2', 'abc.123'] should yield
  # {'abc.123' => ['v1','v2','']}
  def generate_prefix_hash(modified_dois)
    prefix_hash = {}
    modified_dois.sort.each do |d|
      prefix = d
      version = ''
      # This regex will match dois like abc.def.v1 or abc.def.v1.01 etc.
      # but we don't want to match a doi like dryad.v123 since v123 does
      # not appear to be a version suffix but part of the DOI itself
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
