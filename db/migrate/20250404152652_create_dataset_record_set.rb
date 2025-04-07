# frozen_string_literal: true

class CreateDatasetRecordSet < ActiveRecord::Migration[8.0]
  def change
    create_table :dataset_record_sets do |t|
      t.string :provider, null: false
      t.boolean :complete, default: false, null: false
      t.string :job_id
      t.timestamps
    end
  end
end
