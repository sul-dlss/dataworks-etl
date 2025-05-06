# frozen_string_literal: true

# Service for indexing with Solr
class SolrService
  def add(solr_doc:)
    solr.add(solr_doc)
  end

  def delete(id:)
    solr.delete_by_id(id)
  end

  def delete_by_query(query:)
    solr.delete_by_query(query)
  end

  delegate :commit, to: :solr

  private

  def solr
    @solr ||= RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
end
