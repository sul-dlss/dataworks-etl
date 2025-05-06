# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DryadExtractJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set, provider: 'dryad') }

  before do
    allow(Extractors::Dryad).to receive(:call).and_return(dataset_record_set)
  end

  it 'performs extract' do
    described_class.perform_now

    expect(dataset_record_set.reload.job_id).not_to be_nil
    expect(Extractors::Dryad).to have_received(:call)
  end
end
