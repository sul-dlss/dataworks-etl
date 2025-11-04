# frozen_string_literal: true

# Enhances a DataWorks schema metadata record based on the metadata on that record and related sources
class MetadataEnhancer
  def self.call(...)
    new(...).call
  end

  def initialize(mapped_record:)
    @mapped_record = mapped_record.with_indifferent_access
  end

  # @return enhanced metadata record for the dataset with additional metadata
  def call
    add_stanford_authors
    @mapped_record
  end

  # Match stanford contributors and creators with Stanford authorrsbased on ORCIDs
  def add_stanford_authors
    # Do we have any ORCIDs?
    contributors = (@mapped_record[:creators] || []).concat(@mapped_record[:contributors] || [])
    contributors.each do |contributor|
      # Does it have a name section with an identfier
      name_identifiers = contributor[:name_identifiers] || []
      # See if Orcid exists
      orcid = retrieve_metadata_orcid(name_identifiers:)

      if orcid.present?
        author = retrieve_stanford_author(orcid:)
        enhance_author(contributor:, author:) if author.present?
      end
    end
  end

  # Add caps profile id and department names
  def enhance_author(contributor:, author:)
    # Add cap profile id to the name identifiers
    cap_identifier = {
      'name_identifier' => author.cap_profile_id,
      'name_identifier_scheme' => 'CAP'
    }

    # Update creators - if ORCID exists there is already a name identifiers block
    contributor[:name_identifiers] << cap_identifier
    add_departments(contributor:, departments: author.departments) if author.departments.present?
  end

  # Add departments to the affiliation section for creator/contributor metadata
  # If Stanford University does not exist as an affiliation, add that block
  def add_departments(contributor:, departments:)
    affiliation_info = {
      name: 'Stanford University7',
      affiliation_identifier: 'https://ror.org/00f54p054',
      affiliation_identifier_scheme: 'ROR',
      affiliation_department_name: departments
    }

    if contributor[:affiliation].blank?
      contributor[:affiliation] = [affiliation_info]
      return
    end

    # Is there an existing affiliation block for Stanford?
    affiliation_blocks = contributor[:affiliation].select do |a|
      a[:name] == 'Stanford University' || a[:affiliation_identifier] == 'https://ror.org/00f54p054'
    end

    if affiliation_blocks.empty?
      contributor[:affiliation] << affiliation_info
    else
      affiliation_blocks.first[:affiliation_department_name] = departments
    end
  end

  # Retrieve the ORCID, if it exists, from the name identifiers block in the metadata
  def retrieve_metadata_orcid(name_identifiers:)
    name_identifiers.each do |name_identifier_info|
      identifier = name_identifier_info['name_identifier']
      scheme = name_identifier_info['name_identifier_scheme']
      return identifier if (scheme.present? && scheme == 'ORCID') || identifier.start_with?('https://orcid.org/')
    end

    nil
  end

  # Query the Stanford authors table to retrieve the matching author for an ORCID
  def retrieve_stanford_author(orcid:)
    # Use the form of the ORCID that starts with "https://orcid.org"
    orcid = "https://orcid.org/#{orcid}" unless orcid.start_with?('https://orcid.org/')
    authors = StanfordAuthor.where(orcid:, active: true)
    authors.count.positive? ? authors.first : nil
  rescue StandardError
    nil
  end
end
