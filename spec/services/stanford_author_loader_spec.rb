# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StanfordAuthorLoader do
  let(:file_path) { 'spec/fixtures/rialto_data/authors.csv' }

  it 'returns the number of rows imported' do
    expect(described_class.call(file_path:)).to eq(3)
  end

  it 'imports the authors into the database' do
    expect { described_class.call(file_path:) }.to change(StanfordAuthor, :count).by(3)
  end

  it 'maps the CSV columns onto author attributes' do
    described_class.call(file_path:)

    expect(StanfordAuthor.find_by(sunet_id: 'jsmith')).to have_attributes(
      cap_profile_id: '12345',
      full_name: 'Jane Smith',
      first_name: 'Jane',
      last_name: 'Smith',
      orcid: '0000-0001-2345-6789',
      email: 'jsmith@stanford.edu',
      active: true,
      departments: %w[Chemistry Physics]
    )
  end

  it 'treats any non-"true" active value as false' do
    described_class.call(file_path:)

    expect(StanfordAuthor.find_by(sunet_id: 'bwong').active).to be(false)
  end

  context 'when the row count exceeds the batch size' do
    before { stub_const("#{described_class}::BATCH_SIZE", 2) }

    it 'imports every row across multiple batches' do
      expect { described_class.call(file_path:) }.to change(StanfordAuthor, :count).by(3)
    end
  end
end
