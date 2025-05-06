# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RedivisExtractJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set) }

  before do
    allow(Extractors::Redivis).to receive(:call).and_return(dataset_record_set)
  end

  it 'performs extract' do
    described_class.perform_now(organization: 'StanfordPHS')

    expect(dataset_record_set.reload.job_id).not_to be_nil
    expect(Extractors::Redivis).to have_received(:call).with(organization: 'StanfordPHS')
  end
end
