# frozen_string_literal: true

class AddBanners < ActiveRecord::Migration[5.2]
  def change
    create_enum :link_target, %w[self blank]

    create_table :banners, id: :uuid do |t|
      t.string :file_uri, null: false
      t.string :link_url
      t.enum :link_target, enum_type: :link_target
      t.string :alt_text, null: false
      t.datetime :publish_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :expire_at
      t.timestamps
    end
  end
end
