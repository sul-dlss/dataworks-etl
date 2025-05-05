# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchworksExtractJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set) }

  before do
    allow(Extractors::Searchworks).to receive(:call).and_return(dataset_record_set)
  end

  it 'performs extract' do
    described_class.perform_now(solr_params: { q: 'test', rows: 10 }, query_label: 'My Test Query')

    expect(dataset_record_set.reload.job_id).not_to be_nil
    expect(Extractors::Searchworks).to have_received(:call).with(list_args: { params: { q: 'test', rows: 10 } })
  end
end
