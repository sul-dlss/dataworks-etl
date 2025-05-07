# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SdrExtractJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set) }

  before do
    allow(Extractors::Sdr).to receive(:call).and_return(dataset_record_set)
  end

  it 'performs extract' do
    described_class.perform_now

    expect(dataset_record_set.reload.job_id).not_to be_nil
    expect(Extractors::Sdr).to have_received(:call)
  end
end
