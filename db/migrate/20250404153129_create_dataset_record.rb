# frozen_string_literal: true

class CreateDatasetRecord < ActiveRecord::Migration[8.0]
  def change
    create_table :dataset_records do |t|
      t.string :provider, null: false
      t.string :dataset_id, null: false
      t.string :modified_token
      t.string :doi
      t.string :source_md5, null: false
      t.jsonb :source, null: false
      t.timestamps

      t.index %i[provider dataset_id modified_token]
      t.index %i[provider dataset_id source_md5]
      t.index :doi
    end
  end
end
