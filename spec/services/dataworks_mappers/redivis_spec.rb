# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Redivis do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/redivis.json')) }

  it 'maps to Dataworks metadata' do
    expect(metadata).to eq(
      {
        titles: [{ title: 'PRIME India' }],
        creators: [{ name: 'Stanford Center for Population Health Sciences' }],
        publication_year: '2019',
        identifiers: [
          { identifier: '10.57761/m26s-1w59', identifier_type: 'DOI' },
          { identifier: 'stanfordphs.prime_india:016c:v0_1', identifier_type: 'RedivisReference' }
        ],
        url: 'https://redivis.com/datasets/016c-aj7b81qhb?v=0.1',
        access: 'Public',
        provider: 'Redivis',
        descriptions: [{ description: 'The Programme for Improving Mental Health Care ' \
                                      '(PRIME) is creating high quality research evidence ' \
                                      'on how best to implement and expand the coverage of ' \
                                      'mental health treatment programmes in low-resource ' \
                                      'settings. PRIME integrates mental health service ' \
                                      'delivery into primary health care system in India ' \
                                      'through a health systems strengthening approach in ' \
                                      'partnership with researchers, ministries of health ' \
                                      'and non-governmental organisations.',
                         description_type: 'Abstract' }],
        dates: [
          { date: '1990-01-01/2022-12-31', date_type: 'Coverage' },
          { date: '2019-11-22', date_type: 'Created' }
        ],
        subjects: [{ subject: 'india' }, { subject: 'mental health' }],
        sizes: ['0 bytes'],
        version: 'v0.1'
      }
    )
  end
end
