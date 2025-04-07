# frozen_string_literal: true

class CreateDatasetSourceAssociations < ActiveRecord::Migration[8.0]
  def change
    create_table :dataset_source_associations, primary_key: %i[dataset_source_set_id dataset_source_id] do |t|
      t.belongs_to :dataset_source_set, null: false, foreign_key: true
      t.belongs_to :dataset_source, null: false, foreign_key: true
      t.timestamps
    end
  end
end
