# frozen_string_literal: true

# rubocop:disable Rails/CreateTableWithTimestamps
class Init < ActiveRecord::Migration[5.2]
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension 'hstore'
    enable_extension 'pg_trgm'
    enable_extension 'pgcrypto'
    enable_extension 'plpgsql'
    enable_extension 'unaccent'
    enable_extension 'uuid-ossp'

    create_table 'abuse_reports', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'reportable_id'
      t.string 'reportable_type'
      t.uuid 'user_id'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'url'
      t.uuid 'course_id'
    end

    create_table 'additional_quiz_attempts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'quiz_id'
      t.uuid 'user_id'
      t.integer 'count'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'alerts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.jsonb 'translations', default: {}, null: false
      t.datetime 'publish_at'
      t.datetime 'publish_until'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'announcements', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.integer 'lock_version', default: 0, null: false
      t.datetime 'publish_at'
      t.jsonb 'recipients', default: [], null: false
      t.jsonb 'translations', default: {}, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.uuid 'author_id', null: false
    end

    create_table 'answers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'text'
      t.uuid 'question_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'user_id'
      t.uuid 'file_id'
      t.float 'answer_prediction'
      t.float 'sentimental_value'
      t.boolean 'deleted', default: false, null: false
      t.string 'workflow_state', default: 'new', null: false
      t.integer 'ranking'
      t.float 'unhelpful_answer_score'
      t.string 'attachment_uri'
      t.index ['question_id'], name: 'index_answers_on_question_id'
    end

    create_table 'assignment_rules', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'type'
      t.uuid 'user_test_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'authorizations', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.text 'provider', null: false
      t.text 'uid', null: false
      t.text 'token'
      t.text 'secret'
      t.datetime 'expires_at'
      t.text 'info'
      t.index ['provider'], name: 'index_authorizations_on_provider'
      t.index ['user_id'], name: 'index_authorizations_on_user_id'
    end

    create_table 'badges', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.integer 'level'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'course_id'
    end

    create_table 'calendar_events', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'collab_space_id'
      t.string 'title', null: false
      t.text 'description'
      t.datetime 'start_time', null: false
      t.datetime 'end_time', null: false
      t.string 'category'
      t.uuid 'user_id', null: false
      t.boolean 'all_day', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['collab_space_id'], name: 'index_calendar_events_on_collab_space_id'
    end

    create_table 'channels', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'code', null: false
      t.string 'name', null: false
      t.string 'color', null: false
      t.uuid 'logo_id'
      t.uuid 'video_stream_id'
      t.boolean 'public', default: true, null: false
      t.boolean 'archived', default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text 'stage_statement'
      t.uuid 'stage_visual_id'
      t.hstore 'description'
      t.boolean 'highlight', default: false
      t.boolean 'affiliated', default: false, null: false
      t.integer 'position'
      t.uuid 'mobile_visual_id'
      t.string 'logo_uri'
      t.string 'stage_visual_uri'
      t.string 'mobile_visual_uri'
      t.index ['code'], name: 'index_channels_on_code', unique: true
    end

    create_table 'classifiers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'description'
      t.string 'cluster'
      t.string 'cluster_id', null: false
      t.index ['cluster'], name: 'index_classifiers_on_cluster'
    end

    create_table 'classifiers_courses', primary_key: %w[classifier_id course_id], force: :cascade do |t|
      t.uuid 'course_id', null: false
      t.uuid 'classifier_id', null: false
    end

    create_table 'client_applications', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.text 'description'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'clusters', id: :string, force: :cascade do |t|
      t.boolean 'visible', default: true, null: false
      t.jsonb 'translations', default: {}, null: false
    end

    create_table 'collab_space_memberships', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'collab_space_id'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'status'
    end

    create_table 'collab_spaces', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'is_open'
      t.uuid 'course_id'
      t.string 'kind', default: 'group', null: false
      t.text 'description'
      t.text 'details'
    end

    create_table 'comments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'text'
      t.uuid 'commentable_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'user_id'
      t.string 'commentable_type'
      t.float 'sentimental_value'
      t.boolean 'deleted', default: false, null: false
      t.string 'workflow_state', default: 'new', null: false
      t.index %w[commentable_id commentable_type], name: 'index_comments_on_commentable_id_and_commentable_type'
      t.index ['commentable_id'], name: 'index_comments_on_commentable_id'
    end

    create_table 'conflicts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'reason'
      t.boolean 'open', default: true
      t.uuid 'conflict_subject_id'
      t.string 'conflict_subject_type'
      t.uuid 'reporter'
      t.text 'comment'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'accused'
      t.uuid 'peer_assessment_id'
    end

    create_table 'consents', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'treatment_id', null: false
      t.datetime 'created_at', null: false
      t.boolean 'value', default: false, null: false
      t.index ['treatment_id'], name: 'index_consents_on_treatment_id'
      t.index %w[user_id treatment_id], name: 'index_consents_on_user_id_and_treatment_id', unique: true
      t.index ['user_id'], name: 'index_consents_on_user_id'
    end

    create_table 'contexts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'parent_id'
      t.string 'reference_uri'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'course_progresses', primary_key: %w[course_id user_id], force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'course_id', null: false
      t.integer 'visits'
      t.integer 'main_dpoints'
      t.integer 'main_exercises'
      t.integer 'bonus_dpoints'
      t.integer 'bonus_exercises'
      t.integer 'selftest_dpoints'
      t.integer 'selftest_exercises'
      t.index ['course_id'], name: 'index_course_progresses_on_course_id'
    end

    create_table 'course_providers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.string 'provider_type', null: false
      t.jsonb 'config', null: false
      t.boolean 'enabled', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'course_set_entries', primary_key: %w[course_set_id course_id], force: :cascade do |t|
      t.uuid 'course_set_id', null: false
      t.uuid 'course_id', null: false
    end

    create_table 'course_set_relations', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'kind'
      t.uuid 'source_set_id'
      t.uuid 'target_set_id'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'course_sets', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'courses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.string 'status', default: 'preparation'
      t.string 'course_code', null: false
      t.datetime 'start_date'
      t.datetime 'end_date'
      t.text 'abstract'
      t.string 'lang'
      t.uuid 'visual_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'description_rtid'
      t.uuid 'vimeo_id'
      t.boolean 'has_teleboard'
      t.boolean 'records_released'
      t.integer 'enrollment_delta', default: 0, null: false
      t.string 'alternative_teacher_text'
      t.string 'external_course_url'
      t.boolean 'forum_is_locked'
      t.boolean 'affiliated', default: false, null: false
      t.boolean 'hidden', default: false, null: false
      t.text 'welcome_mail'
      t.datetime 'display_start_date'
      t.boolean 'proctored', default: false, null: false
      t.boolean 'auto_archive', default: true
      t.boolean 'show_syllabus', default: true
      t.boolean 'invite_only', default: false
      t.boolean 'deleted', default: false, null: false
      t.uuid 'context_id'
      t.string 'special_groups', default: [], null: false, array: true
      t.uuid 'teacher_ids', default: [], null: false, array: true
      t.datetime 'middle_of_course'
      t.boolean 'on_demand', default: false, null: false
      t.boolean 'show_on_stage', default: false, null: false
      t.uuid 'stage_visual_id'
      t.text 'stage_statement'
      t.uuid 'channel_id'
      t.uuid 'video_provider_id'
      t.boolean 'has_collab_space', default: true
      t.hstore 'policy_url'
      t.integer 'roa_threshold_percentage'
      t.integer 'cop_threshold_percentage'
      t.boolean 'roa_enabled', default: true, null: false
      t.boolean 'cop_enabled', default: true, null: false
      t.boolean 'truerec', default: false
      t.string 'video_course_codes', default: [], null: false, array: true
      t.float 'rating_stars'
      t.integer 'rating_votes'
      t.string 'visual_uri'
      t.string 'stage_visual_uri'
      t.text 'description'
      t.string 'groups', default: [], null: false, array: true
      t.boolean 'enable_video_download', default: true, null: false
      t.hstore 'external_registration_url'
      t.string 'learning_goals', default: [], null: false, array: true
      t.string 'target_groups', default: [], null: false, array: true
      t.index 'lower((course_code)::text)', name: 'index_courses_on_lower_course_code', unique: true
    end

    create_table 'courses_documents', primary_key: %w[course_id document_id], force: :cascade do |t|
      t.uuid 'course_id', null: false
      t.uuid 'document_id', null: false
      t.index ['course_id'], name: 'index_courses_documents_on_course_id'
      t.index ['document_id'], name: 'index_courses_documents_on_document_id'
    end

    create_table 'custom_field_values', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'custom_field_id'
      t.uuid 'context_id'
      t.string 'context_type'
      t.string 'values', default: [], null: false, array: true
      t.index %w[context_type context_id], name: 'index_custom_field_values_on_context_type_and_context_id'
    end

    create_table 'custom_fields', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'context'
      t.string 'name'
      t.string 'title'
      t.string 'type'
      t.boolean 'required'
      t.string 'values', default: [], array: true
      t.string 'default_values', default: [], array: true
      t.string 'validator'
    end

    create_table 'dates', primary_key: %w[slot_id user_id], force: :cascade do |t|
      t.uuid 'slot_id', null: false
      t.uuid 'user_id', default: -> { 'uuid_nil()' }, null: false
      t.uuid 'course_id'
      t.string 'type', null: false
      t.string 'resource_type', null: false
      t.uuid 'resource_id', null: false
      t.datetime 'date', null: false
      t.string 'title', null: false
      t.integer 'section_pos'
      t.integer 'item_pos'
      t.datetime 'visible_after'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[user_id course_id], name: 'index_dates_on_user_id_and_course_id'
    end

    create_table 'deliveries', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'message_id', null: false
      t.uuid 'user_id', null: false
      t.datetime 'sent_at'
      t.datetime 'created_at', null: false
      t.index %w[message_id user_id], name: 'index_deliveries_on_message_id_and_user_id', unique: true
      t.index ['message_id'], name: 'index_deliveries_on_message_id'
    end

    create_table 'document_localizations', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'description'
      t.uuid 'file_id'
      t.string 'revision'
      t.string 'language'
      t.boolean 'deleted', default: false, null: false
      t.uuid 'document_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'file_uri'
      t.index ['document_id'], name: 'index_document_localizations_on_document_id'
    end

    create_table 'documents', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title', comment: 'Admin-facing, not visible to end-users'
      t.text 'description', comment: 'Used by admins, contains information that is not visible to end-users'
      t.boolean 'deleted', default: false, null: false
      t.boolean 'public', default: true, null: false
      t.string 'tags', default: [], array: true
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['title'], name: 'index_documents_on_title'
    end

    create_table 'documents_items', primary_key: %w[document_id item_id], force: :cascade do |t|
      t.uuid 'item_id', null: false
      t.uuid 'document_id', null: false
      t.index ['document_id'], name: 'index_documents_items_on_document_id'
      t.index ['item_id'], name: 'index_documents_items_on_item_id'
    end

    create_table 'emails', id: :serial, force: :cascade do |t|
      t.uuid 'uuid', default: -> { 'gen_random_uuid()' }
      t.uuid 'user_id', null: false
      t.string 'address', null: false
      t.boolean 'primary'
      t.boolean 'confirmed'
      t.datetime 'confirmed_at'
      t.datetime 'created_at'
      t.index 'lower((address)::text)', name: 'index_emails_on_lower_address', unique: true
      t.index ['address'], name: 'index_emails_on_address', unique: true
      t.index ['user_id'], name: 'index_emails_on_user_id'
      t.index ['uuid'], name: 'index_emails_on_uuid', unique: true
    end

    create_table 'enrollments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'course_id'
      t.string 'role'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.float 'quantile'
      t.boolean 'proctored', default: false, null: false
      t.boolean 'deleted', default: false, null: false
      t.datetime 'forced_submission_date'
      t.boolean 'completed'
      t.integer 'quantiled_user_dpoints'
      t.index %w[course_id created_at], name: 'index_enrollments_on_course_id_and_created_at'
      t.index %w[course_id role], name: 'index_enrollments_on_course_id_and_role'
      t.index %w[user_id course_id deleted], name: 'index_enrollments_on_user_id_and_course_id_and_deleted'
      t.index %w[user_id course_id], name: 'index_enrollments_on_user_id_and_course_id', unique: true
      t.index ['user_id'], name: 'index_enrollments_on_user_id'
    end

    create_table 'events', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.string 'key'
      t.boolean 'public'
      t.hstore 'payload'
      t.datetime 'expire_at'
      t.uuid 'course_id'
      t.uuid 'context_id'
      t.uuid 'collab_space_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'link'
      t.index ['public'], name: 'index_events_on_public'
    end

    create_table 'file_versions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'file_id', null: false
      t.string 'original_filename', null: false
      t.string 'blob_uri'
      t.integer 'size', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['file_id'], name: 'index_file_versions_on_file_id'
    end

    create_table 'files', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'collab_space_id', null: false
      t.uuid 'creator_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'title', null: false
      t.text 'description'
      t.index ['collab_space_id'], name: 'index_files_on_collab_space_id'
    end

    create_table 'filters', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'field_name'
      t.string 'field_value'
      t.string 'operator'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'filters_user_tests', primary_key: %w[filter_id user_test_id], force: :cascade do |t|
      t.uuid 'filter_id', null: false
      t.uuid 'user_test_id', null: false
      t.index ['filter_id'], name: 'index_filters_user_tests_on_filter_id'
      t.index ['user_test_id'], name: 'index_filters_user_tests_on_user_test_id'
    end

    create_table 'fixed_learning_evaluations', primary_key: %w[user_id course_id], force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'course_id', null: false
      t.float 'visits_percentage'
      t.integer 'user_dpoints'
      t.integer 'maximal_dpoints'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'flippers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.string 'value'
      t.uuid 'owner_id'
      t.string 'owner_type'
      t.uuid 'context_id', null: false
      t.index ['context_id'], name: 'index_flippers_on_context_id'
      t.index ['name'], name: 'index_flippers_on_name'
      t.index %w[owner_type owner_id], name: 'index_flippers_on_owner_type_and_owner_id'
    end

    create_table 'gallery_votes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.integer 'rating'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'shared_submission_id'
    end

    create_table 'grades', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'submission_id'
      t.float 'base_points'
      t.string 'bonus_points', default: [], array: true
      t.float 'delta'
      t.boolean 'absolute'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['submission_id'], name: 'index_grades_on_submission_id', unique: true
    end

    create_table 'grants', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'context_id'
      t.uuid 'role_id'
      t.uuid 'principal_id'
      t.string 'principal_type'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'groups', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.string 'description'
      t.string 'tags', default: [], null: false, array: true
      t.index ['name'], name: 'index_groups_on_name', unique: true
      t.index ['tags'], name: 'index_groups_on_tags', using: :gin
    end

    create_table 'hangouts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'url'
      t.uuid 'collab_space_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'invoice_addresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.string 'name', null: false
      t.string 'street', null: false
      t.string 'postal_code', null: false
      t.string 'city', null: false
      t.string 'country', null: false
    end

    create_table 'item_results', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'item_id'
      t.uuid 'user_id'
      t.integer 'user_points'
      t.boolean 'visited', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[item_id user_id], name: 'index_item_results_on_item_id_and_user_id', unique: true
      t.index ['item_id'], name: 'index_item_results_on_item_id'
      t.index ['user_id'], name: 'index_item_results_on_user_id'
    end

    create_table 'items', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.datetime 'start_date'
      t.datetime 'end_date'
      t.string 'content_type'
      t.uuid 'section_id'
      t.uuid 'content_id'
      t.boolean 'published', default: true
      t.integer 'position'
      t.boolean 'show_in_nav', default: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'exercise_type'
      t.datetime 'submission_deadline'
      t.datetime 'submission_publishing_date'
      t.integer 'max_dpoints'
      t.boolean 'proctored', default: false, null: false
      t.boolean 'optional', default: false, null: false
      t.uuid 'original_item_id'
      t.string 'icon_type'
      t.boolean 'featured', default: false, null: false
      t.text 'public_description'
      t.boolean 'open_mode', default: true, null: false
      t.integer 'time_effort'
      t.index ['section_id'], name: 'index_items_on_section_id'
    end

    create_table 'knowledge_acquisitions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'learning_unit_id', null: false
      t.uuid 'item_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[learning_unit_id item_id], name: 'index_knowledge_acquisitions_on_learning_unit_id_and_item_id', unique: true
    end

    create_table 'knowledge_examinations', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'learning_unit_id', null: false
      t.uuid 'item_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[learning_unit_id item_id], name: 'index_knowledge_examinations_on_learning_unit_id_and_item_id', unique: true
    end

    create_table 'learning_units', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'objective_id', null: false
      t.integer 'priority', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['objective_id'], name: 'index_learning_units_on_objective_id'
    end

    create_table 'live_events', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'description'
      t.string 'event_type'
      t.text 'speaker'
      t.datetime 'start_at'
      t.string 'further_info'
      t.boolean 'deleted', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.text 'live_video_id'
      t.text 'live_chat_id'
    end

    create_table 'lti_exercises', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.uuid 'lti_provider_id'
      t.uuid 'instructions_rtid'
      t.integer 'allowed_attempts'
      t.string 'custom_fields'
      t.boolean 'is_bonus_exercise'
      t.boolean 'is_main_exercise'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.integer 'weight'
      t.datetime 'lock_submissions_at'
      t.text 'instructions'
    end

    create_table 'lti_gradebooks', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'lti_exercise_id', null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index %w[lti_exercise_id user_id], name: 'index_lti_gradebooks_on_lti_exercise_id_and_user_id', unique: true
    end

    create_table 'lti_grades', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.float 'value'
      t.uuid 'lti_gradebook_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'nonce', null: false
      t.index %w[lti_gradebook_id nonce], name: 'index_lti_grades_on_lti_gradebook_id_and_nonce', unique: true
      t.index ['lti_gradebook_id'], name: 'index_lti_grades_on_lti_gradebook_id'
    end

    create_table 'lti_providers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.string 'domain'
      t.string 'consumer_key'
      t.string 'shared_secret'
      t.text 'custom_fields'
      t.string 'privacy'
      t.text 'description'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'course_id'
      t.string 'presentation_mode'
      t.index ['course_id'], name: 'index_lti_providers_on_course_id'
    end

    create_table 'mail_logs', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'course_id'
      t.uuid 'news_id'
      t.string 'state'
      t.string 'key'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[news_id state], name: 'index_mail_logs_on_news_id_and_state'
      t.index %w[news_id user_id], name: 'index_mail_logs_on_news_id_and_user_id'
    end

    create_table 'memberships', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'group_id', null: false
      t.uuid 'user_id', null: false
      t.index ['group_id'], name: 'index_memberships_on_group_id'
      t.index %w[user_id group_id], name: 'index_memberships_on_user_id_and_group_id', unique: true
    end

    create_table 'messages', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'announcement_id', null: false
      t.jsonb 'recipients', default: [], null: false
      t.jsonb 'translations', default: {}, null: false
      t.boolean 'test', default: false, null: false
      t.string 'status', default: 'preparation', null: false
      t.datetime 'created_at', null: false
      t.uuid 'creator_id', null: false
      t.index ['announcement_id'], name: 'index_messages_on_announcement_id'
    end

    create_table 'metrics', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.boolean 'wait', default: false
      t.integer 'wait_interval', default: 0
      t.string 'type'
      t.string 'distribution'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'metrics_user_tests', primary_key: %w[metric_id user_test_id], force: :cascade do |t|
      t.uuid 'metric_id', null: false
      t.uuid 'user_test_id', null: false
      t.index ['metric_id'], name: 'index_metrics_user_tests_on_metric_id'
      t.index ['user_test_id'], name: 'index_metrics_user_tests_on_user_test_id'
    end

    create_table 'news', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'course_id'
      t.uuid 'author_id'
      t.datetime 'publish_at'
      t.boolean 'show_on_homepage', default: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'state'
      t.integer 'receivers'
      t.integer 'sending_state'
      t.string 'visual_uri'
      t.string 'audience'
    end

    create_table 'news_emails', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'news_id', null: false
      t.uuid 'test_recipient'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'news_translations', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'news_id', null: false
      t.string 'locale', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'title', null: false
      t.text 'text', null: false
      t.text 'teaser', default: '', null: false
      t.index ['locale'], name: 'index_news_translations_on_locale'
      t.index ['news_id'], name: 'index_news_translations_on_news_id'
    end

    create_table 'notes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'subject_id'
      t.string 'subject_type'
      t.uuid 'user_id'
      t.text 'text'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'notifications', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'event_id'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['user_id'], name: 'index_notifications_on_user_id'
    end

    create_table 'oauth_access_grants', id: :serial, force: :cascade do |t|
      t.uuid 'resource_owner_id', null: false
      t.integer 'application_id', null: false
      t.string 'token', null: false
      t.integer 'expires_in', null: false
      t.text 'redirect_uri', null: false
      t.datetime 'created_at', null: false
      t.datetime 'revoked_at'
      t.string 'scopes'
      t.index ['token'], name: 'index_oauth_access_grants_on_token', unique: true
    end

    create_table 'oauth_access_tokens', id: :serial, force: :cascade do |t|
      t.uuid 'resource_owner_id'
      t.integer 'application_id'
      t.string 'token', null: false
      t.string 'refresh_token'
      t.integer 'expires_in'
      t.datetime 'revoked_at'
      t.datetime 'created_at', null: false
      t.string 'scopes'
      t.string 'previous_refresh_token', default: '', null: false
      t.index ['refresh_token'], name: 'index_oauth_access_tokens_on_refresh_token', unique: true
      t.index ['resource_owner_id'], name: 'index_oauth_access_tokens_on_resource_owner_id'
      t.index ['token'], name: 'index_oauth_access_tokens_on_token', unique: true
    end

    create_table 'oauth_applications', id: :serial, force: :cascade do |t|
      t.string 'name', null: false
      t.string 'uid', null: false
      t.string 'secret', null: false
      t.text 'redirect_uri', null: false
      t.string 'scopes', default: '', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['uid'], name: 'index_oauth_applications_on_uid', unique: true
    end

    create_table 'objectives', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'parent_objective_id'
      t.uuid 'context_id', null: false
      t.string 'title', null: false
      t.string 'description'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'position'
      t.string 'completion_type'
      t.boolean 'final', default: false, null: false
      t.index ['context_id'], name: 'index_objectives_on_context_id'
      t.index ['parent_objective_id'], name: 'index_objectives_on_parent_objective_id'
    end

    create_table 'objectives_items', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'item_type', null: false
      t.integer 'time_effort'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.jsonb 'meta', default: {}, null: false
      t.index "((meta ->> 'course_id'::text))", name: 'index_items_on_meta_course_id'
    end

    create_table 'open_badge_templates', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'course_id', null: false
      t.text 'svg'
      t.string 'name'
      t.text 'description'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'file_uri'
      t.index ['course_id'], name: 'index_open_badge_templates_on_course_id', unique: true
    end

    create_table 'open_badges', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'record_id', null: false
      t.uuid 'template_id', null: false
      t.jsonb 'assertion'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'file_uri'
      t.string 'type', default: 'OpenBadge'
      t.index ['type'], name: 'index_open_badges_on_type'
    end

    create_table 'pages', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.string 'locale', null: false
      t.string 'title', null: false
      t.text 'text', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[name locale], name: 'index_pages_on_name_and_locale', unique: true
    end

    create_table 'participants', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'peer_assessment_id'
      t.uuid 'current_step'
      t.integer 'expertise'
      t.float 'grading_weight'
      t.uuid 'completed', default: [], array: true
      t.uuid 'skipped', default: [], array: true
      t.uuid 'group_id'
    end

    create_table 'password_resets', id: :serial, force: :cascade do |t|
      t.uuid 'user_id'
      t.string 'token'
      t.datetime 'created_at'
    end

    create_table 'payments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'product_id', null: false
      t.string 'reference_nr', null: false
      t.string 'status', default: 'created', null: false
      t.json 'payload'
      t.datetime 'completed_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.uuid 'invoice_address_id', null: false
      t.decimal 'vat'
      t.integer 'amount', null: false
      t.uuid 'token', null: false
      t.string 'provider_response_code'
    end

    create_table 'peer_assessment_files', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.string 'storage_uri', null: false
      t.uuid 'user_id', null: false
      t.integer 'size', null: false
      t.string 'mime_type', null: false
      t.uuid 'peer_assessment_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'peer_assessment_groups', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'peer_assessments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'instructions'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'course_id'
      t.uuid 'item_id'
      t.text 'grading_hints'
      t.text 'usage_disclaimer', default: ''
      t.boolean 'allow_gallery_opt_out', default: true
      t.integer 'allowed_attachments', default: 0
      t.string 'allowed_file_types'
      t.integer 'max_file_size', default: 5
      t.uuid 'attachments', default: [], array: true
      t.uuid 'gallery_entries', default: [], array: true
      t.boolean 'video_upload_allowed', default: false
      t.string 'video_provider_name'
      t.boolean 'is_team_assessment', default: false
    end

    create_table 'pinboards', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'topic'
      t.boolean 'supervised'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'policies', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.integer 'version'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.hstore 'url', default: {}, null: false
    end

    create_table 'poll_options', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'text'
      t.integer 'position', null: false
      t.uuid 'poll_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[poll_id position], name: 'index_poll_options_on_poll_id_and_position', unique: true
    end

    create_table 'poll_responses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'poll_id', null: false
      t.uuid 'user_id', null: false
      t.uuid 'choices', null: false, array: true
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[poll_id user_id], name: 'index_poll_responses_on_poll_id_and_user_id', unique: true
    end

    create_table 'polls', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'question'
      t.boolean 'allow_multiple_choices', default: false, null: false
      t.datetime 'start_at', null: false
      t.datetime 'end_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.boolean 'show_intermediate_results', default: true, null: false
    end

    create_table 'pool_entries', id: :serial, force: :cascade do |t|
      t.integer 'resource_pool_id'
      t.integer 'available_locks'
      t.uuid 'submission_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.float 'priority', default: 0.0
      t.index ['created_at'], name: 'index_pool_entries_on_created_at'
      t.index ['submission_id'], name: 'index_pool_entries_on_submission_id'
    end

    create_table 'products', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'context_id', null: false
      t.string 'title', null: false
      t.string 'product_type', null: false
      t.string 'reference_nr_prefix', null: false
      t.integer 'price', null: false
      t.json 'meta'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'progresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_objective_id'
      t.json 'points_progress', default: {}, null: false
      t.json 'visit_progress', default: {}, null: false
      t.boolean 'achievable'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['user_objective_id'], name: 'index_progresses_on_user_objective_id'
    end

    create_table 'providers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.string 'token'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.boolean 'default', default: false, null: false
      t.datetime 'synchronized_at', default: '1970-01-01 00:00:00', null: false
      t.datetime 'run_at', default: '1970-01-01 00:00:00', null: false
    end

    create_table 'question_statistics', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'question_id'
      t.integer 'question_position'
      t.string 'question_type'
      t.string 'question_text'
      t.float 'max_points'
      t.float 'avg_points'
      t.integer 'submission_count', default: 0
      t.integer 'submission_user_count', default: 0
      t.integer 'correct_submission_count', default: 0
      t.integer 'incorrect_submission_count', default: 0
      t.integer 'partly_correct_submission_count', default: 0
      t.jsonb 'answer_statistics', default: []
      t.datetime 'created_at', default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime 'updated_at', default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.index ['question_id'], name: 'index_question_statistics_on_question_id'
    end

    create_table 'questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'text'
      t.string 'title'
      t.uuid 'video_id'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'accepted_answer_id'
      t.uuid 'course_id'
      t.boolean 'discussion_flag', default: false
      t.uuid 'learning_room_id'
      t.uuid 'file_id'
      t.boolean 'sticky', default: false
      t.boolean 'deleted', default: false, null: false
      t.boolean 'closed', default: false
      t.float 'sentimental_value'
      t.string 'text_hash'
      t.string 'workflow_state', default: 'new', null: false
      t.integer 'use_sorting'
      t.integer 'video_timestamp'
      t.integer 'public_answers_count', default: 0, null: false
      t.integer 'public_comments_count', default: 0, null: false
      t.integer 'public_answer_comments_count', default: 0, null: false
      t.string 'attachment_uri'
      t.tsvector 'tsv'
      t.string 'language'
      t.index ['accepted_answer_id'], name: 'index_questions_on_accepted_answer_id'
      t.index %w[course_id user_id title text_hash], name: 'course_double_posting_index', unique: true, where: '(learning_room_id IS NULL)'
      t.index %w[learning_room_id user_id title text_hash], name: 'learning_room_double_posting_index', unique: true
      t.index ['tsv'], name: 'index_questions_on_tsv', using: :gin
    end

    create_table 'questions_tags', primary_key: %w[question_id tag_id], force: :cascade do |t|
      t.uuid 'question_id', null: false
      t.uuid 'tag_id', null: false
      t.index ['tag_id'], name: 'index_questions_tags_on_tag_id'
    end

    create_table 'quiz_answers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'question_id'
      t.string 'comment', limit: 10_000
      t.integer 'position'
      t.boolean 'correct'
      t.uuid 'answer_rtid'
      t.string 'type'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text 'text'
      t.index ['question_id'], name: 'index_quiz_answers_on_quiz_question_id'
    end

    create_table 'quiz_questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'quiz_id'
      t.uuid 'question_rtid'
      t.float 'points'
      t.boolean 'shuffle_answers'
      t.string 'type'
      t.integer 'position', default: 0
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'explanation_rtid'
      t.boolean 'exclude_from_recap', default: false, null: false
      t.boolean 'case_sensitive', default: true, null: false
      t.text 'text'
      t.text 'explanation'
      t.index ['quiz_id'], name: 'index_quiz_questions_on_quiz_id'
    end

    create_table 'quiz_submission_answers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'type'
      t.uuid 'quiz_answer_id'
      t.uuid 'quiz_submission_question_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text 'user_answer_text'
      t.index ['quiz_answer_id'], name: 'index_quiz_submission_answers_on_quiz_answer_id'
      t.index ['quiz_submission_question_id'], name: 'index_quiz_submission_answers_on_quiz_submission_question_id'
    end

    create_table 'quiz_submission_questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'quiz_submission_id'
      t.uuid 'quiz_question_id'
      t.float 'points'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['quiz_question_id'], name: 'index_quiz_submission_questions_on_quiz_question_id'
      t.index %w[quiz_submission_id quiz_question_id], name: 'index_submission_questions_on_submission_id_and_qq_id', unique: true
      t.index ['quiz_submission_id'], name: 'index_quiz_submission_questions_on_quiz_submission_id'
    end

    create_table 'quiz_submission_snapshots', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'quiz_submission_id'
      t.text 'data'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['quiz_submission_id'], name: 'index_quiz_submission_snapshots_on_quiz_submission_id', unique: true
    end

    create_table 'quiz_submissions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'quiz_id'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.datetime 'quiz_submission_time'
      t.uuid 'course_id'
      t.datetime 'quiz_version_at'
      t.float 'fudge_points', default: 0.0
      t.jsonb 'vendor_data', default: {}, null: false
      t.index ['course_id'], name: 'index_quiz_submissions_on_course_id'
      t.index %w[quiz_id user_id], name: 'index_quiz_submissions_on_quiz_id_and_user_id'
      t.index %w[user_id course_id], name: 'index_quiz_submissions_on_user_id_and_course_id'
      t.index ['user_id'], name: 'index_quiz_submissions_on_user_id'
    end

    create_table 'quizzes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'instructions_rtid'
      t.integer 'time_limit_seconds'
      t.integer 'allowed_attempts'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'unlimited_time'
      t.boolean 'unlimited_attempts'
      t.boolean 'skip_welcome_page'
      t.string 'external_ref_id'
      t.text 'instructions'
    end

    create_table 'quotes', id: :serial, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'course_id'
      t.uuid 'question_id'
      t.text 'text'
      t.string 'title'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'read_states', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'news_id', null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['news_id'], name: 'index_read_states_on_news_id'
      t.index ['user_id'], name: 'index_read_states_on_user_id'
    end

    create_table 'records', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'course_id'
      t.uuid 'template_id'
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'type'
      t.text 'render_state'
      t.string 'verification'
      t.boolean 'preview', default: false
      t.uuid 'truerec_id'
      t.index ['verification'], name: 'index_records_on_verification'
    end

    create_table 'reference_nr_counts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'product_id', null: false
      t.integer 'count', default: 0, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['product_id'], name: 'index_reference_nr_counts_on_product_id', unique: true
    end

    create_table 'resource_pools', id: :serial, force: :cascade do |t|
      t.uuid 'peer_assessment_id'
      t.string 'purpose'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'results', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'item_id'
      t.integer 'dpoints', null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['item_id'], name: 'index_results_on_item_id'
      t.index %w[user_id item_id], name: 'index_results_on_user_id_and_item_id'
    end

    create_table 'reviews', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'submission_id'
      t.uuid 'step_id'
      t.uuid 'user_id'
      t.text 'text'
      t.boolean 'submitted'
      t.boolean 'award'
      t.integer 'feedback_grade'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'train_review', default: false
      t.datetime 'deadline'
      t.uuid 'optionIDs', default: [], array: true
      t.boolean 'extended', default: false
      t.string 'worker_jid'
    end

    create_table 'richtexts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'course_id'
      t.text 'text'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'roles', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'permissions', default: [], array: true
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'name'
    end

    create_table 'rubric_options', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'rubric_id'
      t.text 'description', default: ''
      t.integer 'points'
    end

    create_table 'rubrics', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'peer_assessment_id'
      t.string 'title'
      t.boolean 'template', default: false
      t.text 'hints'
      t.integer 'position'
      t.boolean 'team_evaluation', default: false
    end

    create_table 'scores', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'course_id'
      t.string 'rule', null: false
      t.integer 'points', null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text 'data', default: '{}', null: false
      t.string 'checksum'
      t.index %w[checksum rule], name: 'index_scores_on_checksum_and_rule'
      t.index ['rule'], name: 'index_scores_on_rule'
      t.index %w[user_id course_id rule], name: 'index_scores_on_user_id_and_course_id_and_rule'
    end

    create_table 'section_choices', primary_key: %w[user_id section_id], force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'section_id', null: false
      t.uuid 'choice_ids', default: [], array: true
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'section_progresses', primary_key: %w[section_id user_id], force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'section_id', null: false
      t.uuid 'alternative_progress_for'
      t.integer 'visits'
      t.integer 'main_dpoints'
      t.integer 'main_exercises'
      t.integer 'bonus_dpoints'
      t.integer 'bonus_exercises'
      t.integer 'selftest_dpoints'
      t.integer 'selftest_exercises'
    end

    create_table 'sections', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'description'
      t.boolean 'published'
      t.datetime 'start_date'
      t.datetime 'end_date'
      t.uuid 'course_id'
      t.boolean 'optional_section', default: false, null: false
      t.integer 'position'
      t.boolean 'deleted', default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'pinboard_closed', default: false, null: false
      t.string 'alternative_state', default: 'none', null: false
      t.uuid 'parent_id'
      t.index ['course_id'], name: 'index_sections_on_course_id'
      t.index ['parent_id'], name: 'index_sections_on_parent_id'
    end

    create_table 'sessions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.string 'user_agent'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'masquerade_id'
    end

    create_table 'shared_submissions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'peer_assessment_id'
      t.text 'text'
      t.boolean 'submitted'
      t.boolean 'disallowed_sample', default: false
      t.boolean 'gallery_opt_out', default: false
      t.uuid 'attachments', default: [], array: true
      t.integer 'additional_attempts', default: 0
      t.boolean 'has_video_upload', default: false, null: false
      t.string 'video_upload_url'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'steps', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'peer_assessment_id'
      t.datetime 'deadline'
      t.boolean 'optional', default: false
      t.integer 'position', default: 0
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'type'
      t.integer 'required_reviews'
      t.boolean 'open'
      t.datetime 'unlock_date'
      t.string 'deadline_worker_jids', default: [], array: true
    end

    create_table 'streams', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.integer 'vimeo_id'
      t.string 'hd_url'
      t.string 'sd_url'
      t.integer 'width'
      t.integer 'height'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'poster'
      t.uuid 'provider_id'
      t.bigint 'sd_size'
      t.bigint 'hd_size'
      t.bigint 'hls_size'
      t.string 'hls_url'
      t.integer 'duration'
      t.string 'sd_md5'
      t.string 'hd_md5'
      t.string 'hls_md5'
      t.string 'audio_uri'
    end

    create_table 'submission_files', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.string 'storage_uri', null: false
      t.uuid 'user_id', null: false
      t.integer 'size', null: false
      t.string 'mime_type', null: false
      t.uuid 'shared_submission_id', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'submission_video_uploads', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'video_upload_id'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.uuid 'shared_submission_id'
    end

    create_table 'submissions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'grade'
      t.uuid 'shared_submission_id'
      t.index ['shared_submission_id'], name: 'index_submissions_on_shared_submission_id'
      t.index %w[user_id shared_submission_id], name: 'index_submissions_on_user_id_and_shared_submission_id', unique: true
    end

    create_table 'subscriptions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'question_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['question_id'], name: 'index_subscriptions_on_question_id'
    end

    create_table 'subtitle_cues', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'subtitle_id', null: false
      t.integer 'identifier', null: false
      t.interval 'start', default: '00:00:00', null: false
      t.interval 'stop', default: '00:00:00', null: false
      t.text 'text'
      t.string 'style'
      t.index ['subtitle_id'], name: 'index_subtitle_cues_on_subtitle_id'
    end

    create_table 'subtitles', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'video_id', null: false
      t.string 'lang', null: false
      t.boolean 'automatic', default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index %w[video_id lang], name: 'index_subtitles_on_video_id_and_lang', unique: true
    end

    create_table 'tags', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'course_id'
      t.uuid 'learning_room_id'
      t.string 'referenced_resource'
      t.string 'type'
      t.index 'course_id, lower((name)::text)', name: 'course_duplicate_tags_index', unique: true, where: '(learning_room_id IS NULL)'
      t.index 'learning_room_id, lower((name)::text)', name: 'learning_room_duplicate_tags_index', unique: true, where: '(course_id IS NULL)'
      t.index %w[id type], name: 'index_tags_on_id_and_type'
      t.index %w[type referenced_resource], name: 'index_tags_on_type_and_referenced_resource'
    end

    create_table 'teachers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.hstore 'description'
      t.uuid 'picture_id'
      t.uuid 'signature_id'
      t.string 'picture_uri'
      t.uuid 'user_id'
    end

    create_table 'templates', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.text 'dynamic_content'
      t.string 'certificate_type'
      t.uuid 'course_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.integer 'qrcode_x'
      t.integer 'qrcode_y'
      t.string 'file_uri'
      t.index %w[course_id certificate_type], name: 'index_templates_on_course_id_and_certificate_type', unique: true
    end

    create_table 'test_groups', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.float 'ratio'
      t.integer 'index'
      t.uuid 'group_id'
      t.uuid 'user_test_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text 'confidence'
      t.text 'box_plot_data'
      t.boolean 'invalidated_flipper', default: false
      t.integer 'trials_count', default: 0
      t.text 'waiting_count'
      t.text 'mean'
      t.text 'change'
      t.text 'effect'
      t.text 'required_participants'
      t.text 'description', default: '', null: false
      t.string 'flippers', default: [], null: false, array: true
      t.index ['group_id'], name: 'index_test_groups_on_group_id'
      t.index ['user_test_id'], name: 'index_test_groups_on_user_test_id'
    end

    create_table 'thumbnails', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'file_uri'
      t.integer 'start_time'
      t.uuid 'video_id'
    end

    create_table 'tickets', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'url'
      t.string 'title'
      t.text 'report'
      t.string 'topic'
      t.string 'language'
      t.uuid 'user_id'
      t.uuid 'course_id'
      t.text 'data'
      t.string 'mail'
      t.datetime 'created_at'
    end

    create_table 'time_effort_items', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'content_type', null: false
      t.uuid 'content_id', null: false
      t.uuid 'section_id', null: false
      t.uuid 'course_id', null: false
      t.integer 'time_effort'
      t.integer 'calculated_time_effort'
      t.boolean 'time_effort_overwritten', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['course_id'], name: 'index_time_effort_items_on_course_id'
      t.index ['section_id'], name: 'index_time_effort_items_on_section_id'
    end

    create_table 'time_effort_jobs', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'item_id', null: false
      t.uuid 'job_id'
      t.string 'status', default: 'waiting', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'tokens', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.string 'token'
      t.string 'scenario'
      t.string 'owner_type'
      t.integer 'owner_id'
      t.index ['token'], name: 'index_tokens_on_token'
    end

    create_table 'treatments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name', null: false
      t.boolean 'required', default: false, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['name'], name: 'index_treatments_on_name', unique: true
    end

    create_table 'trial_results', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'trial_id'
      t.uuid 'metric_id'
      t.boolean 'waiting', default: false
      t.float 'result'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'trials', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.boolean 'finished', default: false
      t.uuid 'user_test_id'
      t.uuid 'test_group_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.datetime 'finish_time'
      t.index %w[user_test_id user_id], name: 'index_trials_on_user_test_id_and_user_id', unique: true
    end

    create_table 'uploads', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.string 'upload_link'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'vimeo_id'
      t.string 'album_name'
      t.uuid 'provider_id'
    end

    create_table 'user_objectives', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'objective_id', null: false
      t.uuid 'user_id', null: false
      t.boolean 'active', default: true, null: false
      t.datetime 'completed_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[objective_id user_id], name: 'index_user_objectives_on_objective_id_and_user_id', unique: true
      t.index ['user_id'], name: 'index_user_objectives_on_user_id'
    end

    create_table 'user_statuses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'context_id', null: false
      t.hstore 'settings', default: {}, null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index %w[user_id context_id], name: 'index_user_statuses_on_user_id_and_context_id', unique: true
    end

    create_table 'user_tests', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'name'
      t.string 'identifier'
      t.text 'description'
      t.datetime 'start_date'
      t.datetime 'end_date'
      t.integer 'max_participants'
      t.uuid 'course_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.integer 'round_robin_counter', default: 0
      t.boolean 'round_robin', default: false
    end

    create_table 'users', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'password_digest'
      t.string 'display_name'
      t.datetime 'born_at'
      t.string 'language'
      t.string 'timezone'
      t.uuid 'image_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.hstore 'preferences', default: {}, null: false
      t.boolean 'archived', default: false
      t.boolean 'affiliated', default: false, null: false
      t.integer 'accepted_policy_version', default: 0
      t.boolean 'anonymous', default: false
      t.boolean 'confirmed', default: false, null: false
      t.string 'avatar_uri'
      t.string 'full_name', null: false
      t.index ['archived'], name: 'index_users_on_archived'
      t.index ['confirmed'], name: 'index_users_on_confirmed'
      t.index %w[created_at id], name: 'index_users_pagination'
      t.index ['created_at'], name: 'index_users_active', where: '((confirmed = true) AND (archived = false) AND (anonymous = false))'
      t.index ['created_at'], name: 'index_users_on_create_at_where_anonymous', where: '(anonymous = true)'
      t.index ['created_at'], name: 'index_users_on_created_at'
      t.index ['display_name'], name: 'index_users_on_display_name'
      t.index ['full_name'], name: 'index_users_on_full_name'
      t.index ['full_name'], name: 'index_users_on_full_name_gin_trgm', opclass: :gin_trgm_ops, using: :gin
    end

    create_table 'versions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'item_type', null: false
      t.uuid 'item_id', null: false
      t.string 'event', null: false
      t.string 'whodunnit'
      t.text 'object'
      t.datetime 'created_at'
      t.index %w[item_type item_id], name: 'index_versions_on_item_type_and_item_id'
    end

    create_table 'videos', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'title'
      t.text 'description'
      t.uuid 'lecturer_stream_id'
      t.uuid 'slides_stream_id'
      t.uuid 'pip_stream_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'subtitled_stream_id'
      t.integer 'thumbnail_job_counter', default: 0
      t.string 'slides_uri'
      t.string 'transcript_uri'
      t.string 'reading_material_uri'
      t.string 'thumbnails_uri'
      t.index ['lecturer_stream_id'], name: 'index_videos_on_lecturer_stream_id'
      t.index ['pip_stream_id'], name: 'index_videos_on_pip_stream_id'
      t.index ['slides_stream_id'], name: 'index_videos_on_slides_stream_id'
    end

    create_table 'visits', primary_key: %w[user_id item_id], force: :cascade do |t|
      t.uuid 'user_id', null: false
      t.uuid 'item_id', null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['item_id'], name: 'index_visits_on_item_id'
    end

    create_table 'votes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.integer 'value'
      t.uuid 'votable_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.uuid 'user_id'
      t.string 'votable_type'
      t.index %w[votable_id votable_type], name: 'index_votes_on_votable_id_and_votable_type'
    end

    create_table 'vouchers', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.string 'country', null: false
      t.uuid 'course_id'
      t.uuid 'claimant_id'
      t.datetime 'claimed_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.uuid 'product_id', null: false
      t.string 'tag', default: 'untagged', null: false
      t.datetime 'expires_at'
      t.inet 'claimant_ip'
      t.string 'claimant_country', limit: 3
    end

    create_table 'watches', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.uuid 'user_id'
      t.uuid 'question_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.index ['question_id'], name: 'index_watches_on_question_id'
    end

    add_foreign_key 'authorizations', 'users'
    add_foreign_key 'calendar_events', 'collab_spaces'
    add_foreign_key 'classifiers', 'clusters', on_delete: :cascade
    add_foreign_key 'consents', 'treatments'
    add_foreign_key 'consents', 'users'
    add_foreign_key 'course_progresses', 'courses'
    add_foreign_key 'course_set_entries', 'course_sets', on_update: :cascade, on_delete: :restrict
    add_foreign_key 'course_set_entries', 'courses', on_update: :cascade, on_delete: :restrict
    add_foreign_key 'course_set_relations', 'course_sets', column: 'source_set_id', on_update: :cascade, on_delete: :restrict
    add_foreign_key 'course_set_relations', 'course_sets', column: 'target_set_id', on_update: :cascade, on_delete: :restrict
    add_foreign_key 'dates', 'courses'
    add_foreign_key 'deliveries', 'messages'
    add_foreign_key 'file_versions', 'files'
    add_foreign_key 'files', 'collab_spaces'
    add_foreign_key 'messages', 'announcements'
    add_foreign_key 'news_emails', 'news'
    add_foreign_key 'oauth_access_grants', 'oauth_applications', column: 'application_id'
    add_foreign_key 'oauth_access_tokens', 'oauth_applications', column: 'application_id'
    add_foreign_key 'question_statistics', 'quiz_questions', column: 'question_id', on_delete: :cascade
    add_foreign_key 'section_progresses', 'sections'

    create_view :embed_courses, version: 4
  end
end
# rubocop:enable all
