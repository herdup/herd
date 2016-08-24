# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160722234053) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "herd_assets", force: :cascade do |t|
    t.string   "file_name"
    t.integer  "file_size"
    t.string   "content_type"
    t.string   "type"
    t.text     "meta"
    t.integer  "parent_asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transform_id"
    t.integer  "assetable_id"
    t.string   "assetable_type"
    t.integer  "position"
  end

  add_index "herd_assets", ["assetable_id"], name: "index_herd_assets_on_assetable_id", using: :btree
  add_index "herd_assets", ["assetable_type"], name: "index_herd_assets_on_assetable_type", using: :btree
  add_index "herd_assets", ["transform_id"], name: "index_herd_assets_on_transform_id", using: :btree

  create_table "herd_pages", force: :cascade do |t|
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "herd_transforms", force: :cascade do |t|
    t.string   "type"
    t.hstore   "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "assetable_type"
    t.string   "name"
  end

  add_index "herd_transforms", ["assetable_type"], name: "index_herd_transforms_on_assetable_type", using: :btree
  add_index "herd_transforms", ["name"], name: "index_herd_transforms_on_name", using: :btree

  create_table "posts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
