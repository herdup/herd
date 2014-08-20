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

ActiveRecord::Schema.define(version: 20140812174015) do

  create_table "herd_assets", force: true do |t|
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

  create_table "herd_pages", force: true do |t|
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "herd_transforms", force: true do |t|
    t.string   "type"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "assetable_type"
    t.string   "name"
  end

  create_table "posts", force: true do |t|
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
