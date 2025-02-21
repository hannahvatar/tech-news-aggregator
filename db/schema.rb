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

ActiveRecord::Schema[7.1].define(version: 2025_02_21_205728) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "ai_summaries", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "content"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "scraped_article_id"
    t.index ["article_id"], name: "index_ai_summaries_on_article_id"
    t.index ["scraped_article_id"], name: "index_ai_summaries_on_scraped_article_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_on_article_id_and_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "feed_id", null: false
    t.string "title"
    t.string "url"
    t.datetime "published_at"
    t.text "content"
    t.string "author"
    t.string "guid"
    t.index ["feed_id"], name: "index_articles_on_feed_id"
    t.index ["guid"], name: "index_articles_on_guid", unique: true
  end

  create_table "feeds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "url"
    t.string "feed_type"
    t.datetime "last_fetched_at"
    t.index ["url"], name: "index_feeds_on_url", unique: true
  end

  create_table "key_facts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "article_id"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.date "end_date"
    t.jsonb "data", default: {}
  end

  create_table "scraped_articles", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.text "content"
    t.datetime "published_at"
    t.bigint "scraped_feed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "summary"
    t.bigint "article_id"
    t.index ["article_id"], name: "index_scraped_articles_on_article_id"
    t.index ["scraped_feed_id"], name: "index_scraped_articles_on_scraped_feed_id"
    t.index ["url"], name: "index_scraped_articles_on_url", unique: true
  end

  create_table "scraped_feeds", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "feed_type"
    t.datetime "last_scraped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_summaries", "articles"
  add_foreign_key "ai_summaries", "scraped_articles"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "feeds"
  add_foreign_key "scraped_articles", "articles"
  add_foreign_key "scraped_articles", "scraped_feeds"
end
