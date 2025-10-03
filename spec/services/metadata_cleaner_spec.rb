# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataCleaner do
  context 'when the Solr document requires metadata cleanup' do
    let(:solr_doc) { JSON.parse(File.read('spec/fixtures/solr_documents/test.json')) }
    let(:cleaned_up_doc) { described_class.call(solr_doc:) }

    it 'returns field values broken out even when strings have quotation strings delimited by commas' do
      expect(cleaned_up_doc['subjects_ssim']).to contain_exactly('Physics', 'Inelastic X Ray Scattering',
                                                                 'Nonlinear X Ray Dynamics', 'Isxrs', 'Earth Science',
                                                                 'Cryosphere', 'Glaciers/Ice Sheets',
                                                                 'Glacier Motion/Ice Sheet Motion')
    end

    it 'returns field values without opening and closing parentheses' do
      expect(cleaned_up_doc['creators_ssim']).to contain_exactly('Alexandra Trelle', 'Alexander Second')
    end

    it 'converts field values to have the first letter of each word upper case' do
      expect(cleaned_up_doc['publisher_ssi']).to contain_exactly('Figshare')
    end
  end
end
