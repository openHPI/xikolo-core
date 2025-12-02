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

ActiveRecord::Schema[7.2].define(version: 2025_11_17_141733) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_enum :gender, [
    "male",
    "female",
    "diverse",
    "undisclosed",
  ], force: :cascade

  create_enum :link_target, [
    "self",
    "blank",
  ], force: :cascade

  create_enum :node_type, [
    "root",
    "section",
    "item",
    "branch",
    "fork",
  ], force: :cascade

  create_enum :offer_category, [
    "course",
    "certificate",
    "complete",
  ], force: :cascade

  create_enum :payment_frequency, [
    "one_time",
    "weekly",
    "monthly",
    "quarterly",
    "half_yearly",
    "by_semester",
    "yearly",
    "other",
  ], force: :cascade

  create_enum :sort_mode, [
    "automatic",
    "manual",
  ], force: :cascade

  create_enum :state, [
    "BW",
    "BY",
    "BE",
    "BB",
    "HB",
    "HH",
    "HE",
    "MV",
    "NI",
    "NW",
    "RP",
    "SL",
    "SN",
    "ST",
    "SH",
    "TH",
  ], force: :cascade

  create_enum :user_category, [
    "school_student",
    "university_student",
    "teacher",
    "other",
  ], force: :cascade

  create_function :uuid_generate_v7ms, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.uuid_generate_v7ms()
       RETURNS uuid
       LANGUAGE plpgsql
      AS $function$
      begin
        -- use random v4 uuid as starting point (which has the same variant we need)
        -- then overlay timestamp
        -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
        return encode(
          set_bit(
            set_bit(
              overlay(uuid_send(gen_random_uuid())
                      placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                      from 1 for 6
              ),
              52, 1
            ),
            53, 1
          ),
          'hex')::uuid;
      end
      $function$
  SQL

  create_table "abuse_reports", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "reportable_id"
    t.string "reportable_type"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.uuid "course_id"
  end

  create_table "additional_quiz_attempts", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "quiz_id"
    t.uuid "user_id"
    t.integer "count"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "alerts", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.jsonb "translations", default: {}, null: false
    t.datetime "publish_at", precision: nil
    t.datetime "publish_until", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "announcements", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.integer "lock_version", default: 0, null: false
    t.datetime "publish_at", precision: nil
    t.jsonb "recipients", default: [], null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "author_id", null: false
  end

  create_table "answers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "text"
    t.uuid "question_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "user_id"
    t.uuid "file_id"
    t.boolean "deleted", default: false, null: false
    t.string "workflow_state", default: "new", null: false
    t.integer "ranking"
    t.float "unhelpful_answer_score"
    t.string "attachment_uri"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "authorizations", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.text "provider", null: false
    t.text "uid", null: false
    t.text "token"
    t.text "secret"
    t.datetime "expires_at", precision: nil
    t.text "info"
    t.index ["provider"], name: "index_authorizations_on_provider"
    t.index ["user_id"], name: "index_authorizations_on_user_id"
  end

  create_table "badges", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.integer "level"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "course_id"
  end

  create_table "banners", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "file_uri", null: false
    t.string "link_url"
    t.enum "link_target", enum_type: "link_target"
    t.string "alt_text", null: false
    t.datetime "publish_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "expire_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "branches", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "group_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "fork_id", null: false
    t.index ["fork_id"], name: "index_branches_on_fork_id"
    t.index ["group_id"], name: "index_branches_on_group_id"
  end

  create_table "channels", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.uuid "logo_id"
    t.boolean "public", default: true, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "stage_statement"
    t.uuid "stage_visual_id"
    t.hstore "description"
    t.boolean "highlight", default: false
    t.boolean "affiliated", default: false, null: false
    t.integer "position"
    t.uuid "mobile_visual_id"
    t.string "logo_uri"
    t.string "stage_visual_uri"
    t.string "mobile_visual_uri"
    t.jsonb "info_link", default: {}, null: false
    t.jsonb "title_translations", default: {}
    t.index ["code"], name: "index_channels_on_code", unique: true
  end

  create_table "classifiers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.string "cluster_id", null: false
    t.jsonb "translations", default: {}, null: false
    t.integer "position"
    t.jsonb "descriptions", default: {}, null: false
    t.index ["cluster_id"], name: "index_classifiers_on_cluster_id"
  end

  create_table "classifiers_courses", primary_key: ["classifier_id", "course_id"], force: :cascade do |t|
    t.uuid "course_id", null: false
    t.uuid "classifier_id", null: false
    t.integer "position"
  end

  create_table "client_applications", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "clusters", id: :string, force: :cascade do |t|
    t.boolean "visible", default: true, null: false
    t.jsonb "translations", default: {}, null: false
    t.enum "sort_mode", default: "automatic", null: false, enum_type: "sort_mode"
  end

  create_table "comments", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "text"
    t.uuid "commentable_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "user_id"
    t.string "commentable_type"
    t.boolean "deleted", default: false, null: false
    t.string "workflow_state", default: "new", null: false
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
  end

  create_table "conflicts", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "reason"
    t.boolean "open", default: true
    t.uuid "conflict_subject_id"
    t.string "conflict_subject_type"
    t.uuid "reporter"
    t.text "comment"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "accused"
    t.uuid "peer_assessment_id"
  end

  create_table "consents", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "treatment_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.boolean "value", default: false, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["treatment_id"], name: "index_consents_on_treatment_id"
    t.index ["user_id", "treatment_id"], name: "index_consents_on_user_id_and_treatment_id", unique: true
    t.index ["user_id"], name: "index_consents_on_user_id"
  end

  create_table "content_tests", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.string "groups", default: [], null: false, array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "round_robin_counter", default: 0, null: false
    t.string "identifier", null: false
    t.index ["course_id", "identifier"], name: "index_content_tests_on_course_id_and_identifier", unique: true
  end

  create_table "contexts", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "parent_id"
    t.string "reference_uri"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "course_offers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "price_currency", default: "EUR", null: false
    t.enum "payment_frequency", default: "one_time", null: false, enum_type: "payment_frequency"
    t.enum "category", default: "course", null: false, enum_type: "offer_category"
    t.integer "price", default: 0, null: false
    t.uuid "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_offers_on_course_id"
  end

  create_table "course_progresses", primary_key: ["course_id", "user_id"], force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "course_id", null: false
    t.integer "visits", default: 0, null: false
    t.integer "main_dpoints", default: 0, null: false
    t.integer "main_exercises", default: 0, null: false
    t.integer "bonus_dpoints", default: 0, null: false
    t.integer "bonus_exercises", default: 0, null: false
    t.integer "selftest_dpoints", default: 0, null: false
    t.integer "selftest_exercises", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "max_dpoints", default: 0, null: false
    t.integer "max_visits", default: 0, null: false
    t.integer "points_percentage_fpoints", default: 0, null: false
    t.integer "visits_percentage_fpoints", default: 0, null: false
    t.index ["course_id"], name: "index_course_progresses_on_course_id"
  end

  create_table "course_providers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "provider_type", null: false
    t.jsonb "config", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "course_set_entries", primary_key: ["course_set_id", "course_id"], force: :cascade do |t|
    t.uuid "course_set_id", null: false
    t.uuid "course_id", null: false
  end

  create_table "course_set_relations", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "kind"
    t.uuid "source_set_id"
    t.uuid "target_set_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "course_sets", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "course_subscriptions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "course_id"], name: "index_course_subscriptions_on_user_id_and_course_id", unique: true
  end

  create_table "course_visuals", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.uuid "video_id"
    t.string "image_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_visuals_on_course_id", unique: true
  end

  create_table "courses", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.string "status", default: "preparation"
    t.string "course_code", null: false
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.text "abstract"
    t.string "lang"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "description_rtid"
    t.boolean "records_released"
    t.integer "enrollment_delta", default: 0, null: false
    t.string "alternative_teacher_text"
    t.string "external_course_url"
    t.boolean "forum_is_locked"
    t.boolean "affiliated", default: false, null: false
    t.boolean "hidden", default: false, null: false
    t.text "welcome_mail"
    t.datetime "display_start_date", precision: nil
    t.boolean "proctored", default: false, null: false
    t.boolean "auto_archive", default: true
    t.boolean "show_syllabus", default: true
    t.boolean "invite_only", default: false
    t.boolean "deleted", default: false, null: false
    t.uuid "context_id"
    t.string "special_groups", default: [], null: false, array: true
    t.uuid "teacher_ids", default: [], null: false, array: true
    t.datetime "middle_of_course", precision: nil
    t.boolean "on_demand", default: false, null: false
    t.boolean "show_on_stage", default: false, null: false
    t.text "stage_statement"
    t.uuid "channel_id"
    t.hstore "policy_url"
    t.integer "roa_threshold_percentage"
    t.integer "cop_threshold_percentage"
    t.boolean "roa_enabled", default: true, null: false
    t.boolean "cop_enabled", default: true, null: false
    t.string "video_course_codes", default: [], null: false, array: true
    t.float "rating_stars"
    t.integer "rating_votes"
    t.string "stage_visual_uri"
    t.text "description"
    t.string "groups", default: [], null: false, array: true
    t.boolean "enable_video_download", default: true, null: false
    t.hstore "external_registration_url"
    t.string "learning_goals", default: [], null: false, array: true
    t.string "target_groups", default: [], null: false, array: true
    t.boolean "show_on_list", default: true, null: false
    t.text "search_data"
    t.datetime "progress_calculated_at", precision: nil
    t.datetime "progress_stale_at", precision: nil
    t.boolean "pinboard_enabled", default: true, null: false
    t.index "lower((course_code)::text)", name: "index_courses_on_lower_course_code", unique: true
    t.index ["search_data"], name: "index_courses_on_search_data", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "courses_documents", primary_key: ["course_id", "document_id"], force: :cascade do |t|
    t.uuid "course_id", null: false
    t.uuid "document_id", null: false
    t.index ["course_id"], name: "index_courses_documents_on_course_id"
    t.index ["document_id"], name: "index_courses_documents_on_document_id"
  end

  create_table "custom_field_values", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "custom_field_id"
    t.uuid "context_id"
    t.string "context_type"
    t.string "values", default: [], null: false, array: true
    t.index ["context_type", "context_id"], name: "index_custom_field_values_on_context_type_and_context_id"
  end

  create_table "custom_fields", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "context"
    t.string "name"
    t.string "title"
    t.string "type"
    t.boolean "required"
    t.string "values", default: [], array: true
    t.string "default_values", default: [], array: true
    t.string "validator"
  end

  create_table "dates", primary_key: ["slot_id", "user_id"], force: :cascade do |t|
    t.uuid "slot_id", null: false
    t.uuid "user_id", default: -> { "uuid_nil()" }, null: false
    t.uuid "course_id"
    t.string "type", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.datetime "date", precision: nil, null: false
    t.string "title", null: false
    t.integer "section_pos"
    t.integer "item_pos"
    t.datetime "visible_after", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "course_id"], name: "index_dates_on_user_id_and_course_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "deliveries", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "message_id", null: false
    t.uuid "user_id", null: false
    t.datetime "sent_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.index ["message_id", "user_id"], name: "index_deliveries_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_deliveries_on_message_id"
  end

  create_table "document_localizations", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.uuid "file_id"
    t.string "revision"
    t.string "language"
    t.boolean "deleted", default: false, null: false
    t.uuid "document_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "file_uri"
    t.index ["document_id"], name: "index_document_localizations_on_document_id"
  end

  create_table "documents", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title", comment: "Admin-facing, not visible to end-users"
    t.text "description", comment: "Used by admins, contains information that is not visible to end-users"
    t.boolean "deleted", default: false, null: false
    t.boolean "public", default: true, null: false
    t.string "tags", default: [], array: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["title"], name: "index_documents_on_title"
  end

  create_table "documents_items", primary_key: ["document_id", "item_id"], force: :cascade do |t|
    t.uuid "item_id", null: false
    t.uuid "document_id", null: false
    t.index ["document_id"], name: "index_documents_items_on_document_id"
    t.index ["item_id"], name: "index_documents_items_on_item_id"
  end

  create_table "emails", id: :serial, force: :cascade do |t|
    t.uuid "uuid", default: -> { "uuid_generate_v7ms()" }
    t.uuid "user_id", null: false
    t.string "address", null: false
    t.boolean "primary"
    t.boolean "confirmed"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.index "lower((address)::text)", name: "index_emails_on_lower_address", unique: true
    t.index ["address"], name: "index_emails_on_address", unique: true
    t.index ["user_id"], name: "index_emails_on_user_id"
    t.index ["uuid"], name: "index_emails_on_uuid", unique: true
  end

  create_table "enrollments", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "course_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.float "quantile"
    t.boolean "proctored", default: false, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "forced_submission_date", precision: nil
    t.boolean "completed"
    t.integer "quantiled_user_dpoints"
    t.index ["course_id", "created_at"], name: "index_enrollments_on_course_id_and_created_at"
    t.index ["user_id", "course_id", "deleted"], name: "index_enrollments_on_user_id_and_course_id_and_deleted"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "events", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "key"
    t.boolean "public"
    t.hstore "payload"
    t.datetime "expire_at", precision: nil
    t.uuid "course_id"
    t.uuid "context_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "link"
    t.index ["public"], name: "index_events_on_public"
  end

  create_table "fixed_learning_evaluations", primary_key: ["user_id", "course_id"], force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "course_id", null: false
    t.float "visits_percentage"
    t.integer "user_dpoints"
    t.integer "maximal_dpoints"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "flippers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.uuid "owner_id"
    t.string "owner_type"
    t.uuid "context_id", null: false
    t.index ["context_id"], name: "index_flippers_on_context_id"
    t.index ["name"], name: "index_flippers_on_name"
    t.index ["owner_type", "owner_id"], name: "index_flippers_on_owner_type_and_owner_id"
  end

  create_table "forks", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "content_test_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "section_id", null: false
    t.index ["content_test_id"], name: "index_forks_on_content_test_id"
    t.index ["section_id"], name: "index_forks_on_section_id"
  end

  create_table "gallery_votes", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.integer "rating"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "shared_submission_id"
  end

  create_table "grades", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "submission_id"
    t.float "base_points"
    t.string "bonus_points", default: [], array: true
    t.float "delta"
    t.boolean "absolute"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["submission_id"], name: "index_grades_on_submission_id", unique: true
  end

  create_table "grants", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "context_id"
    t.uuid "role_id"
    t.uuid "principal_id"
    t.string "principal_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "groups", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "tags", default: [], null: false, array: true
    t.index ["name"], name: "index_groups_on_name", unique: true
    t.index ["tags"], name: "index_groups_on_tags", using: :gin
  end

  create_table "item_results", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "item_id"
    t.uuid "user_id"
    t.integer "user_points"
    t.boolean "visited", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id", "user_id"], name: "index_item_results_on_item_id_and_user_id", unique: true
    t.index ["item_id"], name: "index_item_results_on_item_id"
    t.index ["user_id"], name: "index_item_results_on_user_id"
  end

  create_table "items", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "content_type"
    t.uuid "section_id"
    t.uuid "content_id"
    t.boolean "published", default: true
    t.integer "position"
    t.boolean "show_in_nav", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "exercise_type"
    t.datetime "submission_deadline", precision: nil
    t.datetime "submission_publishing_date", precision: nil
    t.integer "max_dpoints"
    t.boolean "proctored", default: false, null: false
    t.boolean "optional", default: false, null: false
    t.uuid "original_item_id"
    t.string "icon_type"
    t.boolean "featured", default: false, null: false
    t.text "public_description"
    t.boolean "open_mode", default: true, null: false
    t.integer "time_effort"
    t.uuid "required_item_ids", default: [], null: false, array: true
    t.index ["section_id"], name: "index_items_on_section_id"
  end

  create_table "lti_exercises", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "lti_provider_id"
    t.uuid "instructions_rtid"
    t.integer "allowed_attempts"
    t.string "custom_fields"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "weight"
    t.datetime "lock_submissions_at", precision: nil
    t.text "instructions"
  end

  create_table "lti_gradebooks", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "lti_exercise_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["lti_exercise_id", "user_id"], name: "index_lti_gradebooks_on_lti_exercise_id_and_user_id", unique: true
  end

  create_table "lti_grades", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.float "value"
    t.uuid "lti_gradebook_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "nonce", null: false
    t.index ["lti_gradebook_id", "nonce"], name: "index_lti_grades_on_lti_gradebook_id_and_nonce", unique: true
    t.index ["lti_gradebook_id"], name: "index_lti_grades_on_lti_gradebook_id"
  end

  create_table "lti_providers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.string "domain"
    t.string "consumer_key"
    t.string "shared_secret"
    t.text "custom_fields"
    t.string "privacy", null: false
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "course_id"
    t.string "presentation_mode"
    t.index ["course_id"], name: "index_lti_providers_on_course_id"
  end

  create_table "mail_logs", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "course_id"
    t.uuid "news_id"
    t.string "state"
    t.string "key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["news_id", "state"], name: "index_mail_logs_on_news_id_and_state"
    t.index ["news_id", "user_id"], name: "index_mail_logs_on_news_id_and_user_id"
  end

  create_table "memberships", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "group_id", null: false
    t.uuid "user_id", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
  end

  create_table "messages", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "announcement_id", null: false
    t.jsonb "recipients", default: [], null: false
    t.jsonb "translations", default: {}, null: false
    t.boolean "test", default: false, null: false
    t.string "status", default: "preparation", null: false
    t.datetime "created_at", precision: nil, null: false
    t.uuid "creator_id", null: false
    t.jsonb "consents", default: [], null: false
    t.index ["announcement_id"], name: "index_messages_on_announcement_id"
  end

  create_table "metadata", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.jsonb "data", default: []
    t.string "name", null: false
    t.string "version", null: false
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "name", "version"], name: "index_metadata_on_course_id_and_name_and_version", unique: true
    t.index ["course_id"], name: "index_metadata_on_course_id"
  end

  create_table "news", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id"
    t.uuid "author_id"
    t.datetime "publish_at", precision: nil
    t.boolean "show_on_homepage", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "state"
    t.integer "receivers"
    t.integer "sending_state"
    t.string "visual_uri"
    t.string "audience"
  end

  create_table "news_emails", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "news_id", null: false
    t.uuid "test_recipient"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "news_translations", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "news_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "title", null: false
    t.text "text", null: false
    t.text "teaser", default: "", null: false
    t.index ["locale"], name: "index_news_translations_on_locale"
    t.index ["news_id"], name: "index_news_translations_on_news_id"
  end

  create_table "nodes", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.enum "type", null: false, enum_type: "node_type"
    t.uuid "course_id", null: false
    t.uuid "parent_id"
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.uuid "section_id"
    t.uuid "item_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "fork_id"
    t.uuid "branch_id"
    t.datetime "progress_stale_at", precision: nil
    t.index ["branch_id"], name: "index_nodes_on_branch_id"
    t.index ["course_id"], name: "index_nodes_on_course_id"
    t.index ["fork_id"], name: "index_nodes_on_fork_id"
    t.index ["item_id"], name: "index_nodes_on_item_id"
    t.index ["lft"], name: "index_nodes_on_lft"
    t.index ["parent_id"], name: "index_nodes_on_parent_id"
    t.index ["rgt"], name: "index_nodes_on_rgt"
    t.index ["section_id"], name: "index_nodes_on_section_id"
    t.index ["type"], name: "index_nodes_on_type"
  end

  create_table "notes", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "subject_id"
    t.string "subject_type"
    t.uuid "user_id"
    t.text "text"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "notifications", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "event_id"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "open_badge_templates", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.text "svg"
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "file_uri"
    t.index ["course_id"], name: "index_open_badge_templates_on_course_id", unique: true
  end

  create_table "open_badges", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "record_id", null: false
    t.uuid "template_id", null: false
    t.jsonb "assertion"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "file_uri"
    t.string "type", default: "OpenBadge"
    t.index ["record_id", "template_id"], name: "index_open_badges_on_record_id_and_template_id"
    t.index ["type"], name: "index_open_badges_on_type"
  end

  create_table "pages", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "locale", null: false
    t.string "title", null: false
    t.text "text", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name", "locale"], name: "index_pages_on_name_and_locale", unique: true
  end

  create_table "participants", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "peer_assessment_id"
    t.uuid "current_step"
    t.integer "expertise"
    t.float "grading_weight"
    t.uuid "completed", default: [], array: true
    t.uuid "skipped", default: [], array: true
    t.uuid "group_id"
  end

  create_table "password_resets", id: :serial, force: :cascade do |t|
    t.uuid "user_id"
    t.string "token"
    t.datetime "created_at", precision: nil
  end

  create_table "peer_assessment_files", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "storage_uri", null: false
    t.uuid "user_id", null: false
    t.integer "size", null: false
    t.string "mime_type", null: false
    t.uuid "peer_assessment_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "peer_assessment_groups", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "peer_assessments", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.text "instructions"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "course_id"
    t.uuid "item_id"
    t.text "grading_hints"
    t.text "usage_disclaimer", default: ""
    t.boolean "allow_gallery_opt_out", default: true
    t.integer "allowed_attachments", default: 0
    t.string "allowed_file_types"
    t.integer "max_file_size", default: 5
    t.uuid "attachments", default: [], array: true
    t.uuid "gallery_entries", default: [], array: true
    t.boolean "is_team_assessment", default: false
  end

  create_table "pinboards", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "topic"
    t.boolean "supervised"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "policies", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.integer "version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.hstore "url", default: {}, null: false
  end

  create_table "poll_options", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "text"
    t.integer "position", null: false
    t.uuid "poll_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["poll_id", "position"], name: "index_poll_options_on_poll_id_and_position", unique: true
  end

  create_table "poll_responses", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "poll_id", null: false
    t.uuid "user_id", null: false
    t.uuid "choices", null: false, array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["poll_id", "user_id"], name: "index_poll_responses_on_poll_id_and_user_id", unique: true
  end

  create_table "polls", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "question", null: false
    t.boolean "allow_multiple_choices", default: false, null: false
    t.datetime "start_at", precision: nil, null: false
    t.datetime "end_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "show_intermediate_results", default: true, null: false
  end

  create_table "pool_entries", id: :serial, force: :cascade do |t|
    t.integer "resource_pool_id"
    t.integer "available_locks"
    t.uuid "submission_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.float "priority", default: 0.0
    t.index ["created_at"], name: "index_pool_entries_on_created_at"
    t.index ["submission_id"], name: "index_pool_entries_on_submission_id"
  end

  create_table "progresses", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_objective_id"
    t.json "points_progress", default: {}, null: false
    t.json "visit_progress", default: {}, null: false
    t.boolean "achievable"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_objective_id"], name: "index_progresses_on_user_objective_id"
  end

  create_table "providers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.string "token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "default", default: false, null: false
    t.datetime "synchronized_at", precision: nil, default: "1970-01-01 00:00:00", null: false
    t.datetime "run_at", precision: nil, default: "1970-01-01 00:00:00", null: false
    t.string "provider_type", null: false
    t.jsonb "credentials", default: {}, null: false
  end

  create_table "question_statistics", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "question_id"
    t.integer "question_position"
    t.string "question_type"
    t.string "question_text"
    t.float "max_points"
    t.float "avg_points"
    t.integer "submission_count", default: 0
    t.integer "submission_user_count", default: 0
    t.integer "correct_submission_count", default: 0
    t.integer "incorrect_submission_count", default: 0
    t.integer "partly_correct_submission_count", default: 0
    t.jsonb "answer_statistics", default: []
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["question_id"], name: "index_question_statistics_on_question_id"
  end

  create_table "questions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "text"
    t.string "title"
    t.uuid "video_id"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "accepted_answer_id"
    t.uuid "course_id"
    t.boolean "discussion_flag", default: false
    t.uuid "file_id"
    t.boolean "sticky", default: false
    t.boolean "deleted", default: false, null: false
    t.boolean "closed", default: false
    t.string "text_hash"
    t.string "workflow_state", default: "new", null: false
    t.integer "video_timestamp"
    t.integer "public_answers_count", default: 0, null: false
    t.integer "public_comments_count", default: 0, null: false
    t.integer "public_answer_comments_count", default: 0, null: false
    t.string "attachment_uri"
    t.tsvector "tsv"
    t.string "language"
    t.index ["accepted_answer_id"], name: "index_questions_on_accepted_answer_id"
    t.index ["course_id", "user_id", "title", "text_hash"], name: "course_double_posting_index", unique: true
    t.index ["tsv"], name: "index_questions_on_tsv", using: :gin
  end

  create_table "questions_tags", primary_key: ["question_id", "tag_id"], force: :cascade do |t|
    t.uuid "question_id", null: false
    t.uuid "tag_id", null: false
    t.index ["tag_id"], name: "index_questions_tags_on_tag_id"
  end

  create_table "quiz_answers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "question_id"
    t.string "comment", limit: 10000
    t.integer "position"
    t.boolean "correct"
    t.uuid "answer_rtid"
    t.string "type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "text"
    t.index ["question_id"], name: "index_quiz_answers_on_quiz_question_id"
  end

  create_table "quiz_questions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "quiz_id"
    t.uuid "question_rtid"
    t.float "points"
    t.boolean "shuffle_answers"
    t.string "type"
    t.integer "position", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "explanation_rtid"
    t.boolean "exclude_from_recap", default: false, null: false
    t.boolean "case_sensitive", default: true, null: false
    t.text "text"
    t.text "explanation"
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quiz_submission_answers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "quiz_answer_id"
    t.uuid "quiz_submission_question_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "user_answer_text"
    t.index ["quiz_answer_id"], name: "index_quiz_submission_answers_on_quiz_answer_id"
    t.index ["quiz_submission_question_id"], name: "index_quiz_submission_answers_on_quiz_submission_question_id"
  end

  create_table "quiz_submission_questions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "quiz_submission_id"
    t.uuid "quiz_question_id"
    t.float "points"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["quiz_question_id"], name: "index_quiz_submission_questions_on_quiz_question_id"
    t.index ["quiz_submission_id", "quiz_question_id"], name: "index_submission_questions_on_submission_id_and_qq_id", unique: true
    t.index ["quiz_submission_id"], name: "index_quiz_submission_questions_on_quiz_submission_id"
  end

  create_table "quiz_submission_snapshots", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "quiz_submission_id"
    t.text "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["quiz_submission_id"], name: "index_quiz_submission_snapshots_on_quiz_submission_id", unique: true
  end

  create_table "quiz_submissions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "quiz_id"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "quiz_submission_time", precision: nil
    t.uuid "course_id"
    t.datetime "quiz_version_at", precision: nil
    t.float "fudge_points", default: 0.0
    t.jsonb "vendor_data", default: {}, null: false
    t.index ["course_id"], name: "index_quiz_submissions_on_course_id"
    t.index ["quiz_id", "user_id"], name: "index_quiz_submissions_on_quiz_id_and_user_id"
    t.index ["user_id", "course_id"], name: "index_quiz_submissions_on_user_id_and_course_id"
    t.index ["user_id"], name: "index_quiz_submissions_on_user_id"
  end

  create_table "quizzes", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "instructions_rtid"
    t.integer "time_limit_seconds"
    t.integer "allowed_attempts"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "unlimited_time"
    t.boolean "unlimited_attempts"
    t.boolean "skip_welcome_page"
    t.string "external_ref_id"
    t.text "instructions"
  end

  create_table "read_states", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "news_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["news_id"], name: "index_read_states_on_news_id"
    t.index ["user_id"], name: "index_read_states_on_user_id"
  end

  create_table "records", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id"
    t.uuid "template_id"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type"
    t.text "render_state"
    t.string "verification"
    t.boolean "preview", default: false
    t.index ["verification"], name: "index_records_on_verification"
  end

  create_table "resource_pools", id: :serial, force: :cascade do |t|
    t.uuid "peer_assessment_id"
    t.string "purpose"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "results", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "item_id"
    t.integer "dpoints", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "index_results_on_item_id"
    t.index ["user_id", "item_id"], name: "index_results_on_user_id_and_item_id"
  end

  create_table "reviews", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "submission_id"
    t.uuid "step_id"
    t.uuid "user_id"
    t.text "text"
    t.boolean "submitted"
    t.boolean "award"
    t.integer "feedback_grade"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "train_review", default: false
    t.datetime "deadline", precision: nil
    t.uuid "optionIDs", default: [], array: true
    t.boolean "extended", default: false
    t.string "worker_jid"
  end

  create_table "richtexts", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "course_id"
    t.text "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "permissions", default: [], array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
  end

  create_table "rubric_options", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "rubric_id"
    t.text "description", default: ""
    t.integer "points"
  end

  create_table "rubrics", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "peer_assessment_id"
    t.string "title"
    t.boolean "template", default: false
    t.text "hints"
    t.integer "position"
    t.boolean "team_evaluation", default: false
  end

  create_table "scores", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "course_id"
    t.string "rule", null: false
    t.integer "points", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "data", default: "{}", null: false
    t.string "checksum"
    t.index ["checksum", "rule"], name: "index_scores_on_checksum_and_rule"
    t.index ["rule"], name: "index_scores_on_rule"
    t.index ["user_id", "course_id", "rule"], name: "index_scores_on_user_id_and_course_id_and_rule"
  end

  create_table "section_choices", primary_key: ["user_id", "section_id"], force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "section_id", null: false
    t.uuid "choice_ids", default: [], array: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "section_progresses", primary_key: ["section_id", "user_id"], force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "section_id", null: false
    t.uuid "alternative_progress_for"
    t.integer "visits", default: 0, null: false
    t.integer "main_dpoints", default: 0, null: false
    t.integer "main_exercises", default: 0, null: false
    t.integer "bonus_dpoints", default: 0, null: false
    t.integer "bonus_exercises", default: 0, null: false
    t.integer "selftest_dpoints", default: 0, null: false
    t.integer "selftest_exercises", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sections", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.boolean "published"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.uuid "course_id"
    t.boolean "optional_section", default: false, null: false
    t.integer "position"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "pinboard_closed", default: false, null: false
    t.string "alternative_state", default: "none", null: false
    t.uuid "parent_id"
    t.datetime "progress_stale_at", precision: nil
    t.uuid "required_section_ids", default: [], null: false, array: true
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["parent_id"], name: "index_sections_on_parent_id"
  end

  create_table "sessions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "user_agent"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "masquerade_id"
    t.date "access_at", default: -> { "CURRENT_DATE" }, null: false
    t.index ["access_at"], name: "index_sessions_on_access_at"
  end

  create_table "shared_submissions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "peer_assessment_id"
    t.text "text"
    t.boolean "submitted"
    t.boolean "disallowed_sample", default: false
    t.boolean "gallery_opt_out", default: false
    t.uuid "attachments", default: [], array: true
    t.integer "additional_attempts", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "steps", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "peer_assessment_id"
    t.datetime "deadline", precision: nil
    t.boolean "optional", default: false
    t.integer "position", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type"
    t.integer "required_reviews"
    t.boolean "open"
    t.datetime "unlock_date", precision: nil
    t.string "deadline_worker_jids", default: [], array: true
  end

  create_table "streams", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.string "hd_url"
    t.string "sd_url"
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "poster"
    t.uuid "provider_id"
    t.bigint "sd_size"
    t.bigint "hd_size"
    t.bigint "hls_size"
    t.string "hls_url"
    t.integer "duration"
    t.string "sd_md5"
    t.string "hd_md5"
    t.string "hls_md5"
    t.string "audio_uri"
    t.string "sd_download_url"
    t.string "hd_download_url"
    t.string "provider_video_id", null: false
    t.datetime "downloads_expire", precision: nil
  end

  create_table "submission_files", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "storage_uri", null: false
    t.uuid "user_id", null: false
    t.integer "size", null: false
    t.string "mime_type", null: false
    t.uuid "shared_submission_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "submissions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "grade"
    t.uuid "shared_submission_id"
    t.index ["shared_submission_id"], name: "index_submissions_on_shared_submission_id"
    t.index ["user_id", "shared_submission_id"], name: "index_submissions_on_user_id_and_shared_submission_id", unique: true
  end

  create_table "subscriptions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "question_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["question_id"], name: "index_subscriptions_on_question_id"
  end

  create_table "subtitle_cues", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "subtitle_id", null: false
    t.integer "identifier", null: false
    t.interval "start", default: "PT0S", null: false
    t.interval "stop", default: "PT0S", null: false
    t.text "text"
    t.string "style"
    t.index ["subtitle_id"], name: "index_subtitle_cues_on_subtitle_id"
  end

  create_table "subtitles", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "video_id", null: false
    t.string "lang", null: false
    t.boolean "automatic", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["video_id", "lang"], name: "index_subtitles_on_video_id_and_lang", unique: true
  end

  create_table "tags", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "course_id"
    t.string "referenced_resource"
    t.string "type"
    t.index "course_id, lower((name)::text)", name: "course_duplicate_tags_index", unique: true
    t.index ["id", "type"], name: "index_tags_on_id_and_type"
    t.index ["type", "referenced_resource"], name: "index_tags_on_type_and_referenced_resource"
  end

  create_table "teachers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name"
    t.hstore "description"
    t.uuid "picture_id"
    t.uuid "signature_id"
    t.string "picture_uri"
    t.uuid "user_id"
  end

  create_table "templates", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.text "dynamic_content"
    t.string "certificate_type"
    t.uuid "course_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "qrcode_x"
    t.integer "qrcode_y"
    t.string "file_uri"
    t.index ["course_id", "certificate_type"], name: "index_templates_on_course_id_and_certificate_type", unique: true
  end

  create_table "thumbnails", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "file_uri"
    t.integer "start_time"
    t.uuid "video_id"
  end

  create_table "tickets", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "url"
    t.string "title"
    t.text "report"
    t.string "topic"
    t.string "language"
    t.uuid "user_id"
    t.uuid "course_id"
    t.text "data"
    t.string "mail"
    t.datetime "created_at", precision: nil
  end

  create_table "time_effort_items", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "content_type", null: false
    t.uuid "content_id", null: false
    t.uuid "section_id", null: false
    t.uuid "course_id", null: false
    t.integer "time_effort"
    t.integer "calculated_time_effort"
    t.boolean "time_effort_overwritten", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id"], name: "index_time_effort_items_on_course_id"
    t.index ["section_id"], name: "index_time_effort_items_on_section_id"
  end

  create_table "time_effort_jobs", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "item_id", null: false
    t.uuid "job_id"
    t.string "status", default: "waiting", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "token"
    t.string "scenario"
    t.string "owner_type"
    t.integer "owner_id"
    t.index ["token"], name: "index_tokens_on_token"
  end

  create_table "treatments", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "required", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "consent_manager", default: {}, null: false
    t.index ["name"], name: "index_treatments_on_name", unique: true
  end

  create_table "user_statuses", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "context_id", null: false
    t.hstore "settings", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "context_id"], name: "index_user_statuses_on_user_id_and_context_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "password_digest"
    t.string "display_name"
    t.datetime "born_at", precision: nil
    t.string "language"
    t.string "timezone"
    t.uuid "image_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.hstore "preferences", default: {}, null: false
    t.boolean "archived", default: false
    t.boolean "affiliated", default: false, null: false
    t.integer "accepted_policy_version", default: 0
    t.boolean "anonymous", default: false
    t.boolean "confirmed", default: false, null: false
    t.string "avatar_uri"
    t.string "full_name", null: false
    t.date "last_access"
    t.string "country"
    t.enum "state", enum_type: "state"
    t.string "city"
    t.enum "gender", enum_type: "gender"
    t.enum "status", enum_type: "user_category"
    t.index ["archived"], name: "index_users_on_archived"
    t.index ["confirmed"], name: "index_users_on_confirmed"
    t.index ["created_at", "id"], name: "index_users_pagination"
    t.index ["created_at"], name: "index_users_active", where: "((confirmed = true) AND (archived = false) AND (anonymous = false))"
    t.index ["created_at"], name: "index_users_on_create_at_where_anonymous", where: "(anonymous = true)"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["display_name"], name: "index_users_on_display_name"
    t.index ["full_name"], name: "index_users_on_full_name"
    t.index ["full_name"], name: "index_users_on_full_name_gin_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["last_access"], name: "index_users_on_last_access"
  end

  create_table "versions", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "item_type", null: false
    t.uuid "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "videos", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.uuid "lecturer_stream_id"
    t.uuid "slides_stream_id"
    t.uuid "pip_stream_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "subtitled_stream_id"
    t.integer "thumbnail_job_counter", default: 0
    t.string "slides_uri"
    t.string "transcript_uri"
    t.string "reading_material_uri"
    t.string "thumbnails_uri"
    t.index ["lecturer_stream_id"], name: "index_videos_on_lecturer_stream_id"
    t.index ["pip_stream_id"], name: "index_videos_on_pip_stream_id"
    t.index ["slides_stream_id"], name: "index_videos_on_slides_stream_id"
  end

  create_table "visits", primary_key: ["user_id", "item_id"], force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "item_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "index_visits_on_item_id"
    t.index ["user_id", "item_id"], name: "index_visits_on_user_id_and_item_id", unique: true
  end

  create_table "votes", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.integer "value"
    t.uuid "votable_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "user_id"
    t.string "votable_type"
    t.index ["votable_id", "votable_type"], name: "index_votes_on_votable_id_and_votable_type"
  end

  create_table "vouchers", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.string "country", null: false
    t.uuid "course_id"
    t.uuid "claimant_id"
    t.datetime "claimed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "tag", default: "untagged", null: false
    t.datetime "expires_at", precision: nil
    t.inet "claimant_ip"
    t.string "claimant_country", limit: 3
    t.string "product_type", null: false
  end

  create_table "watches", id: :uuid, default: -> { "uuid_generate_v7ms()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "question_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["question_id"], name: "index_watches_on_question_id"
  end

  create_table "well_known_files", primary_key: "filename", id: { type: :string, limit: 64 }, force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "authorizations", "users"
  add_foreign_key "branches", "forks"
  add_foreign_key "branches", "groups"
  add_foreign_key "classifiers", "clusters", on_delete: :cascade
  add_foreign_key "classifiers_courses", "classifiers", on_delete: :cascade
  add_foreign_key "classifiers_courses", "courses", on_delete: :cascade
  add_foreign_key "consents", "treatments"
  add_foreign_key "consents", "users"
  add_foreign_key "content_tests", "courses"
  add_foreign_key "course_offers", "courses"
  add_foreign_key "course_progresses", "courses"
  add_foreign_key "course_set_entries", "course_sets", on_update: :cascade, on_delete: :restrict
  add_foreign_key "course_set_entries", "courses", on_update: :cascade, on_delete: :restrict
  add_foreign_key "course_set_relations", "course_sets", column: "source_set_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "course_set_relations", "course_sets", column: "target_set_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "course_subscriptions", "courses"
  add_foreign_key "course_subscriptions", "users"
  add_foreign_key "dates", "courses"
  add_foreign_key "deliveries", "messages"
  add_foreign_key "forks", "content_tests"
  add_foreign_key "forks", "sections"
  add_foreign_key "messages", "announcements"
  add_foreign_key "metadata", "courses"
  add_foreign_key "news_emails", "news"
  add_foreign_key "nodes", "branches"
  add_foreign_key "nodes", "courses"
  add_foreign_key "nodes", "forks"
  add_foreign_key "nodes", "items"
  add_foreign_key "nodes", "nodes", column: "parent_id"
  add_foreign_key "nodes", "sections"
  add_foreign_key "question_statistics", "quiz_questions", column: "question_id", on_delete: :cascade
  add_foreign_key "section_progresses", "sections"

  create_view "embed_courses", sql_definition: <<-SQL
      SELECT ARRAY( SELECT hstore(classifiers.*) AS hstore
             FROM (classifiers_courses
               JOIN classifiers ON ((classifiers_courses.classifier_id = classifiers.id)))
            WHERE (classifiers_courses.course_id = courses.id)) AS fixed_classifiers,
      COALESCE(alternative_teacher_text, (array_to_string(ARRAY( SELECT teachers.name
             FROM teachers
            WHERE (teachers.id = ANY (courses.teacher_ids))
            ORDER BY ( SELECT c.pos
                     FROM ( SELECT courses_1.id,
                              generate_subscripts(courses_1.teacher_ids, 1) AS pos,
                              courses_1.teacher_ids
                             FROM courses courses_1) c
                    WHERE ((courses.id = c.id) AND (teachers.id = c.teacher_ids[c.pos])))), ', '::text))::character varying) AS teacher_text,
      id,
      title,
      status,
      course_code,
      start_date,
      end_date,
      abstract,
      lang,
      created_at,
      updated_at,
      description_rtid,
      records_released,
      enrollment_delta,
      alternative_teacher_text,
      external_course_url,
      forum_is_locked,
      affiliated,
      hidden,
      welcome_mail,
      display_start_date,
      proctored,
      auto_archive,
      show_syllabus,
      invite_only,
      deleted,
      context_id,
      special_groups,
      teacher_ids,
      middle_of_course,
      on_demand,
      show_on_stage,
      stage_statement,
      channel_id,
      policy_url,
      roa_threshold_percentage,
      cop_threshold_percentage,
      roa_enabled,
      cop_enabled,
      video_course_codes,
      rating_stars,
      rating_votes,
      stage_visual_uri,
      description,
      groups,
      enable_video_download,
      external_registration_url,
      learning_goals,
      target_groups,
      show_on_list,
      search_data,
      progress_calculated_at,
      progress_stale_at,
      pinboard_enabled
     FROM courses;
  SQL
end
