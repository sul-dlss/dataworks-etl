# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Extractors::Local do
  context 'when successful' do
    subject(:dataset_record_set) { described_class.call(path: 'spec/fixtures/local_datasets') }

    it 'creates a dataset record set' do
      expect { dataset_record_set }
        .to change(DatasetRecordSet, :count).by(1)
        .and change(DatasetRecord, :count).by(1)

      new_dataset_record = DatasetRecord.find_by!(dataset_id: 'example')
      expect(new_dataset_record.provider).to eq('local')
      expect(new_dataset_record.modified_token).to eq('8c4885d95728e7c6c4a3e2286ad8c480')
      expect(new_dataset_record.doi).to eq('10.1234/5678')
      expect(new_dataset_record.source).to be_a(Hash)
      expect(new_dataset_record.source_md5).to be_a(String)

      expect(dataset_record_set.provider).to eq('local')
      expect(dataset_record_set.complete).to be true
      expect(dataset_record_set.dataset_records).to include(new_dataset_record)
    end
  end
end
