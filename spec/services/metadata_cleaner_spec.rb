# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataCleaner do
  context 'when the Solr document requires metadata cleanup' do
    let(:solr_doc) { JSON.parse(File.read('spec/fixtures/solr_documents/test.json')) }
    let(:cleaned_up_doc) { described_class.call(solr_doc:) }

    it 'returns field values broken out even when strings have quotation strings delimited by commas' do
      expect(cleaned_up_doc['subjects_ssim']).to contain_exactly('Physics', 'Inelastic X-ray scattering',
                                                                 'Nonlinear X-ray dynamics', 'ISXRS', 'EARTH SCIENCE',
                                                                 'CRYOSPHERE', 'GLACIERS/ICE SHEETS',
                                                                 'GLACIER MOTION/ICE SHEET MOTION')
    end

    it 'returns field values without opening and closing parentheses' do
      expect(cleaned_up_doc['creators_ssim']).to contain_exactly('Alexandra Trelle', 'Alexander Second')
    end

    it 'removes leading and trailing white space' do
      expect(cleaned_up_doc['publisher_ssi']).to contain_exactly('figshare')
    end

    it 'breaks out author fields by semicolon' do
      expect(cleaned_up_doc['contributors_ssim']).to contain_exactly('Winnie', 'Eeyore', 'Tigger')
    end
  end
end
