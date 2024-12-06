# frozen_string_literal: true

class AddExternalConsents < ActiveRecord::Migration[6.0]
  def change
    add_column :treatments, :consent_manager, :jsonb, default: {}, null: false
  end
end
