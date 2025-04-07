class AddJobIdToDatasetSourceSet < ActiveRecord::Migration[8.0]
  def change
    add_column :dataset_source_sets, :job_id, :string
  end
end
