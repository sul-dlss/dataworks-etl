# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrService do
  let(:solr_service) { described_class.new }

  let(:rsolr) { instance_double(RSolr::Client, commit: true, add: true, delete_by_id: true) }

  before do
    allow(RSolr).to receive(:connect).and_return(rsolr)
  end

  describe '#add' do
    let(:document) { { id: '123', title: 'Test Document' } }

    it 'adds a document to Solr' do
      solr_service.add(solr_doc: document)
      expect(rsolr).to have_received(:add).with(document)
    end
  end

  describe '#commit' do
    it 'commits changes to Solr' do
      solr_service.commit
      expect(rsolr).to have_received(:commit)
    end
  end

  describe '#delete' do
    let(:document_id) { '123' }

    it 'deletes a document from Solr' do
      solr_service.delete(id: document_id)
      expect(rsolr).to have_received(:delete_by_id).with(document_id)
    end
  end
end
