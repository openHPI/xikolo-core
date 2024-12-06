# frozen_string_literal: true

class AddSortModeToClusters < ActiveRecord::Migration[6.0]
  def change
    create_enum :sort_mode, %w[automatic manual]

    change_table :clusters do |t|
      t.enum :sort_mode, enum_type: :sort_mode, null: false, default: 'automatic'
    end
  end
end
