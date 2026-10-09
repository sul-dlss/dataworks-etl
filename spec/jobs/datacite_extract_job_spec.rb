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

  it 'sets organization name based on affiliation' do
    job_instance = job.new(affiliation: 'affiliation')
    job_instance.perform_now

    expect(job_instance.checkin_key).to eq('datacite_extract_job_affiliation_checkin')
  end

  it 'sets organization name based on client id' do
    job_instance = job.new(client_id: 'client id')
    job_instance.perform_now

    expect(job_instance.checkin_key).to eq('datacite_extract_job_client_id_checkin')
  end

  it 'sets organization name based on provider id' do
    job_instance = job.new(provider_id: 'provider')
    job_instance.perform_now

    expect(job_instance.checkin_key).to eq('datacite_extract_job_provider_checkin')
  end
end
