# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Redivis do
  subject(:metadata) { described_class.call(source:) }

  let(:source) { JSON.parse(File.read('spec/fixtures/sources/redivis.json')) }

  it 'maps to Redivis metadata' do
    expect(metadata).to eq(
      {
        doi: '10.57761/m26s-1w59',
        titles: [{ title: 'PRIME India' }],
        creators: [{ name: 'Stanford Center for Population Health Sciences' }],
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
        dates: [{ date: '2019-11-22', date_type: 'Created' }],
        version: 'v0.1'
      }
    )
  end
end
