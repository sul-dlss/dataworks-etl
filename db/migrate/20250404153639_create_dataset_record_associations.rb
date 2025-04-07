# frozen_string_literal: true

class CreateDatasetRecordAssociations < ActiveRecord::Migration[8.0]
  def change
    create_table :dataset_record_associations, primary_key: %i[dataset_record_set_id dataset_record_id] do |t|
      t.belongs_to :dataset_record_set, null: false, foreign_key: true
      t.belongs_to :dataset_record, null: false, foreign_key: true
      t.timestamps
    end
  end
end
