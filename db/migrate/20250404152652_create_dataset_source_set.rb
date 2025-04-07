# frozen_string_literal: true

class CreateDatasetSourceSet < ActiveRecord::Migration[8.0]
  def change
    create_table :dataset_source_sets do |t|
      t.string :provider, null: false
      t.boolean :complete, default: false, null: false
      t.timestamps
    end
  end
end
