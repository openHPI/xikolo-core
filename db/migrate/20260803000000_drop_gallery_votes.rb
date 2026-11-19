# frozen_string_literal: true

class DropGalleryVotes < ActiveRecord::Migration[7.2]
  def up
    drop_table :gallery_votes, if_exists: true
  end

  def down
    create_table :gallery_votes, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.datetime :created_at, precision: nil
      t.integer :rating
      t.uuid :shared_submission_id
      t.datetime :updated_at, precision: nil
      t.uuid :user_id
    end
  end
end
