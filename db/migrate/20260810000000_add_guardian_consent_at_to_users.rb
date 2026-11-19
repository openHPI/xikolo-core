# frozen_string_literal: true

class AddGuardianConsentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :guardian_consent_at, :datetime
  end
end
