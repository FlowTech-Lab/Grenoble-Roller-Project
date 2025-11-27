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

ActiveRecord::Schema[8.1].define(version: 2025_11_24_020634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "attendances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "payment_id"
    t.string "status", limit: 20, default: "registered", null: false
    t.string "stripe_customer_id", limit: 255
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "wants_reminder", default: false, null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["payment_id"], name: "index_attendances_on_payment_id"
    t.index ["user_id", "event_id"], name: "index_attendances_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
    t.index ["wants_reminder"], name: "index_attendances_on_wants_reminder"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", limit: 80, null: false
    t.bigint "actor_user_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata"
    t.integer "target_id", null: false
    t.string "target_type", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_user_id"], name: "index_audit_logs_on_actor_user_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 255, null: false
    t.text "message", null: false
    t.string "name", limit: 140, null: false
    t.string "subject", limit: 140, null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.integer "attendances_count", default: 0, null: false
    t.string "cover_image_url", limit: 255
    t.datetime "created_at", null: false
    t.bigint "creator_user_id", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.text "description", null: false
    t.decimal "distance_km", precision: 6, scale: 2
    t.integer "duration_min", null: false
    t.string "level", limit: 20
    t.string "location_text", limit: 255, null: false
    t.integer "max_participants", default: 0, null: false
    t.decimal "meeting_lat", precision: 9, scale: 6
    t.decimal "meeting_lng", precision: 9, scale: 6
    t.integer "price_cents", default: 0, null: false
    t.bigint "route_id"
    t.timestamptz "start_at", null: false
    t.string "status", limit: 20, default: "draft", null: false
    t.string "title", limit: 140, null: false
    t.datetime "updated_at", null: false
    t.index ["creator_user_id"], name: "index_events_on_creator_user_id"
    t.index ["route_id"], name: "index_events_on_route_id"
    t.index ["status", "start_at"], name: "index_events_on_status_and_start_at"
  end

  create_table "option_types", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "presentation", limit: 100
    t.index ["name"], name: "index_option_types_on_name", unique: true
  end

  create_table "option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_type_id", null: false
    t.string "presentation", limit: 100
    t.datetime "updated_at", null: false
    t.string "value", limit: 50, null: false
    t.index ["option_type_id"], name: "index_option_values_on_option_type_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.integer "variant_id", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["variant_id"], name: "index_order_items_on_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.integer "donation_cents", default: 0, null: false
    t.bigint "payment_id"
    t.string "status", default: "pending", null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["payment_id"], name: "index_orders_on_payment_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "organizer_applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "motivation"
    t.datetime "reviewed_at", precision: nil
    t.bigint "reviewed_by_id"
    t.string "status", limit: 20, default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reviewed_by_id"], name: "index_organizer_applications_on_reviewed_by_id"
    t.index ["user_id"], name: "index_organizer_applications_on_user_id"
  end

  create_table "partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "logo_url", limit: 255
    t.string "name", limit: 140, null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 255
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at"
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "provider", limit: 20, null: false
    t.string "provider_payment_id"
    t.string "status", limit: 20, default: "succeeded", null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 120, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_product_categories_on_slug", unique: true
  end

  create_table "product_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "image_url"
    t.boolean "is_active", default: true, null: false
    t.integer "price_cents", null: false
    t.bigint "product_id", null: false
    t.string "sku", limit: 80, null: false
    t.integer "stock_qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.text "description"
    t.string "image_url", limit: 255
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 140, null: false
    t.integer "price_cents", null: false
    t.string "slug", limit: 160, null: false
    t.integer "stock_qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["is_active", "slug"], name: "index_products_on_is_active_and_slug"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "code", limit: 50, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "level", limit: 2, null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "difficulty", limit: 20
    t.decimal "distance_km", precision: 5, scale: 2
    t.integer "elevation_m"
    t.string "gpx_url", limit: 255
    t.string "map_image_url", limit: 255
    t.string "name", limit: 140, null: false
    t.text "safety_notes"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.boolean "email_verified", default: false, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone", limit: 10
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role_id", null: false
    t.string "skill_level"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["skill_level"], name: "index_users_on_skill_level"
  end

  create_table "variant_option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_value_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id", null: false
    t.index ["option_value_id"], name: "index_variant_option_values_on_option_value_id"
    t.index ["variant_id", "option_value_id"], name: "index_variant_option_values_on_variant_id_and_option_value_id", unique: true
    t.index ["variant_id"], name: "index_variant_option_values_on_variant_id"
  end

  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "payments"
  add_foreign_key "attendances", "users"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "events", "routes"
  add_foreign_key "events", "users", column: "creator_user_id"
  add_foreign_key "option_values", "option_types"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants", column: "variant_id"
  add_foreign_key "orders", "payments"
  add_foreign_key "orders", "users"
  add_foreign_key "organizer_applications", "users"
  add_foreign_key "organizer_applications", "users", column: "reviewed_by_id"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "product_categories", column: "category_id"
  add_foreign_key "users", "roles"
  add_foreign_key "variant_option_values", "option_values"
  add_foreign_key "variant_option_values", "product_variants", column: "variant_id"
end
