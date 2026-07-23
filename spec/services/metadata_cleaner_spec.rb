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

  context 'with parentheses' do
    let(:solr_doc) do
      {
        'creators_ssim' => ['Auckland Academic Health Alliance (AAHA)', '(Alexander Second)'],
        'funders_ssim' => ['Portable Network Graphics (PNG)'],
        'subjects_ssim' => ['METAGENOME ASSEMBLED GENOMES (MAGs)']
      }
    end
    let(:cleaned_up_doc) { described_class.call(solr_doc:) }

    it 'keeps the closing parenthesis of a trailing acronym' do
      expect(cleaned_up_doc['funders_ssim']).to eq(['Portable Network Graphics (PNG)'])
      expect(cleaned_up_doc['subjects_ssim']).to eq(['METAGENOME ASSEMBLED GENOMES (MAGs)'])
    end

    it 'still unwraps a fully parenthesized value while keeping trailing acronyms' do
      expect(cleaned_up_doc['creators_ssim']).to contain_exactly('Auckland Academic Health Alliance (AAHA)',
                                                                 'Alexander Second')
    end
  end

  context 'with duplicate values in a field' do
    let(:solr_doc) { { 'contributors_ssim' => %w[Winnie Eeyore Winnie] } }
    let(:cleaned_up_doc) { described_class.call(solr_doc:) }

    it 'dedupes values within a field' do
      expect(cleaned_up_doc['contributors_ssim']).to eq(%w[Winnie Eeyore])
    end
  end

  context 'with hierarchical and marked-up subjects (#303)' do
    let(:solr_doc) do
      {
        'subjects_ssim' => [
          'EARTH SCIENCE &gt; LAND SURFACE &gt; SOILS',
          'EARTH SCIENCE &gt; LAND SURFACE &gt; SOILS &gt; MICROFAUNA:GCMD',
          '<i>Asclepias</i>',
          'ANIMALS/VERTEBRATES'
        ]
      }
    end
    let(:cleaned_up_doc) { described_class.call(solr_doc:) }

    it 'splits hierarchy, strips markup and scheme suffixes, and dedupes terms' do
      expect(cleaned_up_doc['subjects_ssim']).to eq(
        ['EARTH SCIENCE', 'LAND SURFACE', 'SOILS', 'MICROFAUNA', 'Asclepias', 'ANIMALS/VERTEBRATES']
      )
    end

    it 'splits on a literal (unencoded) ">" hierarchy' do
      doc = { 'subjects_ssim' => ['Earth Science > Solid Earth > Seismology > Earthquake Dynamics'] }
      expect(described_class.call(solr_doc: doc)['subjects_ssim']).to eq(
        ['Earth Science', 'Solid Earth', 'Seismology', 'Earthquake Dynamics']
      )
    end
  end
end
