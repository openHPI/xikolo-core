# frozen_string_literal: true

class CreateShortsTable < ActiveRecord::Migration[7.2]
  def change
    create_enum :short_status, %w[
      preparation
      active
      archived
    ]

    create_table :shorts, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.jsonb :title_translations, null: false, default: {}
      t.jsonb :description_translations, null: false, default: {}

      t.references :course,
        null: false,
        type: :uuid,
        foreign_key: true

      t.enum :status,
        enum_type: :short_status,
        null: false,
        default: :preparation

      t.timestamps
    end
  end
end
