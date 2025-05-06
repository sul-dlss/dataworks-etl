# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataciteExtractJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set, provider: 'datacite') }

  before do
    allow(Extractors::Datacite).to receive(:call).and_return(dataset_record_set)
  end

  it 'performs extract' do
    described_class.perform_now

    expect(dataset_record_set.reload.job_id).not_to be_nil
    expect(Extractors::Datacite).to have_received(:call)
  end
end
