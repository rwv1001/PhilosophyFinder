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

ActiveRecord::Schema.define(version: 20170117045738) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "crawler_pages", force: :cascade do |t|
    t.integer "result_page_id"
    t.string  "URL"
    t.string  "name"
    t.string  "ancestry"
    t.integer "domain_crawler_id"
    t.date    "download_date"
  end

  add_index "crawler_pages", ["ancestry"], name: "index_crawler_pages_on_ancestry", using: :btree
  add_index "crawler_pages", ["domain_crawler_id"], name: "index_crawler_pages_on_domain_crawler_id", using: :btree

  create_table "crawler_ranges", force: :cascade do |t|
    t.integer "user_id"
    t.integer "begin_id"
    t.integer "end_id"
  end

  add_index "crawler_ranges", ["user_id"], name: "index_crawler_ranges_on_user_id", using: :btree

  create_table "display_nodes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "crawler_page_id"
  end

  add_index "display_nodes", ["crawler_page_id"], name: "index_display_nodes_on_crawler_page_id", using: :btree
  add_index "display_nodes", ["user_id"], name: "index_display_nodes_on_user_id", using: :btree

  create_table "domain_crawlers", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "permissions"
    t.integer  "permissions_group_id"
    t.integer  "version",              default: 1
    t.string   "domain_home_page"
    t.string   "short_name"
    t.integer  "crawler_page_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "domain_crawlers", ["crawler_page_id"], name: "index_domain_crawlers_on_crawler_page_id", using: :btree

  create_table "group_elements", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "note"
    t.integer  "group_name_id"
    t.integer  "search_result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "paragraph_id"
  end

  add_index "group_elements", ["group_name_id"], name: "index_group_elements_on_group_name_id", using: :btree
  add_index "group_elements", ["paragraph_id"], name: "group_elements_paragraph_id_ix", using: :btree
  add_index "group_elements", ["search_result_id"], name: "index_group_elements_on_search_result_id", using: :btree

  create_table "group_names", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "ancestry"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paragraphs", force: :cascade do |t|
    t.text    "content"
    t.integer "result_page_id"
    t.text    "deaccented_content", default: ""
    t.boolean "accented",           default: false
  end

  add_index "paragraphs", ["result_page_id"], name: "result_page_id_ix", using: :btree

  create_table "prelim_results", force: :cascade do |t|
    t.integer "search_query_id"
    t.integer "sentence_id"
  end

  add_index "prelim_results", ["search_query_id"], name: "index_prelim_results_on_search_query_id", using: :btree

  create_table "regex_instances", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "regex_templated_id"
    t.string   "argument"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regex_templates", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "expression"
    t.string   "arg_names"
    t.text     "help"
    t.string   "join_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "result_pages", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "hash_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "crawler_page_id"
    t.text     "content"
  end

  add_index "result_pages", ["hash_value"], name: "hash_value_ix", using: :btree

  create_table "save_my_sqls", force: :cascade do |t|
    t.text "save_str"
  end

  create_table "save_sqls", force: :cascade do |t|
    t.text "sql_str"
  end

  create_table "search_queries", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "start_index"
    t.integer  "view_priority"
    t.string   "first_search_term"
    t.string   "second_search_term"
    t.string   "third_search_term"
    t.string   "fourth_search_term"
    t.integer  "word_separation"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_queries", ["user_id"], name: "index_search_queries_on_user_id", using: :btree

  create_table "search_results", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "permissions"
    t.integer  "permissions_group_id"
    t.integer  "search_query_id"
    t.text     "highlighted_result"
    t.string   "hash_value"
    t.integer  "sentence_id"
    t.integer  "crawler_page_id"
    t.boolean  "hidden",                     default: false
    t.boolean  "selected",                   default: false
    t.integer  "begin_display_paragraph_id"
    t.integer  "end_display_paragraph_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_results", ["search_query_id"], name: "search_query_id_ix", using: :btree

  create_table "sentences", force: :cascade do |t|
    t.text    "content"
    t.integer "paragraph_id"
    t.text    "deaccented_content", default: ""
    t.boolean "accented",           default: false
  end

  add_index "sentences", ["paragraph_id"], name: "paragraph_id_ix", using: :btree

  create_table "super_users", force: :cascade do |t|
    t.integer "user_id"
  end

  add_index "super_users", ["user_id"], name: "index_super_users_on_user_id", using: :btree

  create_table "user_paragraphs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "paragraph_id"
  end

  add_index "user_paragraphs", ["paragraph_id"], name: "index_user_paragraphs_on_paragraph_id", using: :btree
  add_index "user_paragraphs", ["user_id"], name: "index_user_paragraphs_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "second_name"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "auth_token"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.integer  "group_id"
    t.integer  "search_query_id"
  end

  create_table "word_pairs", force: :cascade do |t|
    t.integer "word_multiple",  limit: 8
    t.integer "separation"
    t.integer "result_page_id"
    t.integer "sentence_id"
  end

  add_index "word_pairs", ["result_page_id"], name: "index_word_pairs_on_result_page_id", using: :btree
  add_index "word_pairs", ["sentence_id"], name: "sentence_id_ix", using: :btree
  add_index "word_pairs", ["word_multiple"], name: "word_multiple_id_ix", using: :btree

  create_table "word_singletons", force: :cascade do |t|
    t.integer "word_id"
    t.integer "result_page_id"
    t.integer "sentence_id"
    t.integer "paragraph_id"
  end

  add_index "word_singletons", ["paragraph_id"], name: "word_singletons_paragraph_id_ix", using: :btree
  add_index "word_singletons", ["result_page_id"], name: "index_word_singletons_on_result_page_id", using: :btree
  add_index "word_singletons", ["sentence_id"], name: "ws_sentence_id_ix", using: :btree
  add_index "word_singletons", ["word_id"], name: "word_id_ix", using: :btree

  create_table "words", primary_key: "word_name", force: :cascade do |t|
    t.integer "id_value"
    t.integer "word_prime"
  end

  add_index "words", ["id_value"], name: "index_words_on_id_value", using: :btree
  add_index "words", ["word_prime"], name: "index_words_on_word_prime", using: :btree

end
