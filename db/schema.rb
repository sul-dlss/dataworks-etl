# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_07_121739) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dataset_source_associations", primary_key: ["dataset_source_set_id", "dataset_source_id"], force: :cascade do |t|
    t.bigint "dataset_source_set_id", null: false
    t.bigint "dataset_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_source_id"], name: "index_dataset_source_associations_on_dataset_source_id"
    t.index ["dataset_source_set_id"], name: "index_dataset_source_associations_on_dataset_source_set_id"
  end

  create_table "dataset_source_sets", force: :cascade do |t|
    t.string "provider", null: false
    t.boolean "complete", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job_id"
  end

  create_table "dataset_sources", force: :cascade do |t|
    t.string "provider", null: false
    t.string "dataset_id", null: false
    t.string "modified_token"
    t.string "doi"
    t.string "source_md5", null: false
    t.jsonb "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doi"], name: "index_dataset_sources_on_doi"
    t.index ["provider", "dataset_id", "modified_token"], name: "idx_on_provider_dataset_id_modified_token_fc6ab1ba4c"
    t.index ["provider", "dataset_id", "source_md5"], name: "idx_on_provider_dataset_id_source_md5_c38c00e08d"
  end

  add_foreign_key "dataset_source_associations", "dataset_source_sets"
  add_foreign_key "dataset_source_associations", "dataset_sources"
end
