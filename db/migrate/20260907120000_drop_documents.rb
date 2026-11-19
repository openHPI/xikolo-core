# frozen_string_literal: true

class DropDocuments < ActiveRecord::Migration[8.1]
  def change
    drop_table :courses_documents, primary_key: %w[course_id document_id] do |t|
      t.uuid :course_id, null: false
      t.uuid :document_id, null: false
      t.index [:course_id], name: :index_courses_documents_on_course_id
      t.index [:document_id], name: :index_courses_documents_on_document_id
    end

    drop_table :document_localizations, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.timestamps precision: nil
      t.boolean :deleted, default: false, null: false
      t.text :description
      t.uuid :document_id
      t.uuid :file_id
      t.string :file_uri
      t.string :language
      t.string :revision
      t.string :title
      t.index [:document_id], name: :index_document_localizations_on_document_id
    end

    drop_table :documents, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.timestamps precision: nil
      t.boolean :deleted, default: false, null: false
      t.text :description, comment: 'Used by admins, contains information that is not visible to end-users'
      t.boolean :public, default: true, null: false
      t.string :tags, default: [], array: true
      t.string :title, comment: 'Admin-facing, not visible to end-users'
      t.index [:title], name: :index_documents_on_title
    end

    drop_table :documents_items, primary_key: %w[document_id item_id] do |t|
      t.uuid :document_id, null: false
      t.uuid :item_id, null: false
      t.index [:document_id], name: :index_documents_items_on_document_id
      t.index [:item_id], name: :index_documents_items_on_item_id
    end
  end
end
