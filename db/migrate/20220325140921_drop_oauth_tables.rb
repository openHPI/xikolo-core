# frozen_string_literal: true

class DropOauthTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :oauth_access_grants
    drop_table :oauth_access_tokens
    drop_table :oauth_applications
  end
end
