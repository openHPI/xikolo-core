# frozen_string_literal: true

class AddAllowAccessAfterDeadlineToLtiProviders < ActiveRecord::Migration[7.2]
  def change
    add_column :lti_providers, :allow_access_after_deadline, :boolean, default: false, null: false
  end
end
