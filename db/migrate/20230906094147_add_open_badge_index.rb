# frozen_string_literal: true

class AddOpenBadgeIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :open_badges, %i[record_id template_id]
  end
end
