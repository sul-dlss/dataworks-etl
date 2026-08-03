# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RialtoAuthorRefreshJob do
  before do
    allow(RialtoAuthorRefresh).to receive(:call).and_return(10)
  end

  it 'refreshes the RIALTO author data' do
    described_class.perform_now

    expect(RialtoAuthorRefresh).to have_received(:call)
  end
end
