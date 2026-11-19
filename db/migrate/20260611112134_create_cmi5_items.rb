# frozen_string_literal: true

class CreateCmi5Items < ActiveRecord::Migration[7.2]
  def change
    create_table :cmi5_items, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.timestamps
    end
  end
end
