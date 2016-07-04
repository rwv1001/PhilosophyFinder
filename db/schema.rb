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

  create_table "crawler_pages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "result_page_id"
    t.string  "URL"
    t.integer "domain_crawler_id"
  end

  create_table "domain_crawlers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "version"
    t.string   "domain_name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "group_elements", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.integer  "search_result_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "group_names", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "paragraphs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text    "content",        limit: 65535
    t.integer "result_page_id"
    t.index ["result_page_id"], name: "result_page_id_ix", using: :btree
  end

  create_table "regex_instances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "regex_templated_id"
    t.string   "argument"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "regex_templates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "expression"
    t.string   "arg_names"
    t.text     "help",       limit: 65535
    t.string   "join_code"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "result_pages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.text     "content",    limit: 65535
    t.string   "hash_value"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["hash_value"], name: "hash_value_ix", using: :btree
  end

  create_table "search_queries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "domain"
    t.integer  "regex_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "search_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "search_query_id"
    t.integer  "page_id"
    t.integer  "marker_begin"
    t.integer  "marker_end"
    t.integer  "display_begin"
    t.integer  "display_end"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "sentences", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text    "content",      limit: 65535
    t.integer "paragraph_id"
    t.index ["paragraph_id"], name: "paragraph_id_ix", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "second_name"
    t.string   "password_digest"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "auth_token"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.integer  "group_id"
    t.integer  "search_query_id"
  end

  create_table "word_pairs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "word_1"
    t.integer "word_2"
    t.integer "separation"
    t.integer "result_page_id"
    t.integer "sentence_id"
    t.index ["word_1", "word_2", "result_page_id"], name: "index_word_pairs_on_word_1_and_word_2_and_result_page_id", using: :btree
  end

  create_table "word_singletons", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "word_id"
    t.integer "result_page_id"
    t.integer "sentence_id"
    t.index ["word_id"], name: "word_id_ix", using: :btree
  end

  create_table "words", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "word_name"
    t.index ["word_name"], name: "word_name_ix", using: :btree
  end

end
