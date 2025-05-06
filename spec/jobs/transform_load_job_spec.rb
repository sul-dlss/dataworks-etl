# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransformLoadJob do
  let(:job) { described_class }

  let(:dataset_record_set) { create(:dataset_record_set) }

  before do
    allow(TransformerLoader).to receive(:call)
  end

  it 'performs extract' do
    described_class.perform_now

    expect(TransformerLoader).to have_received(:call).with(load_id: String)
  end
end
