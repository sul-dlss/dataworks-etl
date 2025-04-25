class AddEtlKeyToDatasetRecordSet < ActiveRecord::Migration[8.0]
  def change
    add_column :dataset_record_sets, :extractor, :string
    add_column :dataset_record_sets, :list_args, :string
    add_index :dataset_record_sets, [:extractor, :list_args]
  end
end
