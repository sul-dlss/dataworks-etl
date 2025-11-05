class CreateStanfordAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :stanford_authors do |t|
      t.string :sunet_id
      t.string :full_name
      t.string :first_name
      t.string :last_name
      t.string :orcid
      t.string :cap_profile_id
      t.index  :cap_profile_id
      t.string :email
      t.boolean :active
      t.string :departments, array: true, default: []
      t.timestamps
    end
  end
end
