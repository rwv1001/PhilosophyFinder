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

ActiveRecord::Schema.define(version: 20160702135332) do

  create_table "crawler_pages", force: :cascade do |t|
    t.integer "result_page_id",    limit: 4
    t.string  "URL",               limit: 255
    t.string  "ancestry",          limit: 255
    t.integer "domain_crawler_id", limit: 4
  end

  add_index "crawler_pages", ["ancestry"], name: "index_crawler_pages_on_ancestry", using: :btree
  add_index "crawler_pages", ["domain_crawler_id"], name: "index_crawler_pages_on_domain_crawler_id", using: :btree
  add_index "crawler_pages", ["result_page_id"], name: "index_crawler_pages_on_result_page_id", using: :btree

  create_table "domain_crawlers", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "permissions",          limit: 4
    t.integer  "permissions_group_id", limit: 4
    t.integer  "version",              limit: 4,     default: 1
    t.string   "domain_home_page",     limit: 255
    t.string   "short_name",           limit: 255
    t.integer  "crawler_page_id",      limit: 4
    t.text     "description",          limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "domain_crawlers", ["crawler_page_id"], name: "index_domain_crawlers_on_crawler_page_id", using: :btree

  create_table "group_elements", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "group_id",         limit: 4
    t.integer  "search_result_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_names", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.string   "ancestry",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paragraphs", force: :cascade do |t|
    t.text    "content",        limit: 65535
    t.integer "result_page_id", limit: 4
  end

  add_index "paragraphs", ["result_page_id"], name: "result_page_id_ix", using: :btree

  create_table "regex_instances", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "regex_templated_id", limit: 4
    t.string   "argument",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regex_templates", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.string   "expression", limit: 255
    t.string   "arg_names",  limit: 255
    t.text     "help",       limit: 65535
    t.string   "join_code",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "result_pages", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "hash_value", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "result_pages", ["hash_value"], name: "hash_value_ix", using: :btree

  create_table "search_queries", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "first_search_term",  limit: 255
    t.string   "second_search_term", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_results", force: :cascade do |t|
    t.integer  "user_id",                    limit: 4
    t.integer  "permissions",                limit: 4
    t.integer  "permissions_group_id",       limit: 4
    t.integer  "search_query_id",            limit: 4
    t.text     "highlighted_result",         limit: 65535
    t.integer  "sentence_id",                limit: 4
    t.integer  "crawler_page_id",            limit: 4
    t.boolean  "hidden",                                   default: false
    t.boolean  "selected",                                 default: false
    t.integer  "begin_display_paragraph_id", limit: 4
    t.integer  "end_display_paragraph_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_results", ["search_query_id"], name: "search_query_id_ix", using: :btree

  create_table "sentences", force: :cascade do |t|
    t.text    "content",      limit: 65535
    t.integer "paragraph_id", limit: 4
  end

  add_index "sentences", ["paragraph_id"], name: "paragraph_id_ix", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                     limit: 255
    t.string   "first_name",                limit: 255
    t.string   "second_name",               limit: 255
    t.string   "password_digest",           limit: 255
    t.integer  "current_page",              limit: 4,   default: 0
    t.integer  "current_domain_crawler_id", limit: 4,   default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "auth_token",                limit: 255
    t.string   "password_reset_token",      limit: 255
    t.datetime "password_reset_sent_at"
    t.integer  "group_id",                  limit: 4
    t.integer  "search_query_id",           limit: 4
  end

  create_table "word_pairs", force: :cascade do |t|
    t.integer "word_multiple",  limit: 4
    t.integer "separation",     limit: 4
    t.integer "result_page_id", limit: 4
    t.integer "sentence_id",    limit: 4
  end

  add_index "word_pairs", ["word_multiple"], name: "word_multiple_id_ix", using: :btree

  create_table "word_singletons", force: :cascade do |t|
    t.integer "word_id",        limit: 4
    t.integer "result_page_id", limit: 4
    t.integer "sentence_id",    limit: 4
  end

  add_index "word_singletons", ["word_id"], name: "word_id_ix", using: :btree

  create_table "words", force: :cascade do |t|
    t.string  "word_name",  limit: 255
    t.integer "word_prime", limit: 4
  end

  add_index "words", ["word_name"], name: "word_name_ix", using: :btree

end
