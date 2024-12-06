# frozen_string_literal: true

class SupplementVideoProvidersToSupportMultipleTypes < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    change_table :providers, bulk: true do |t|
      t.string :provider_type
      t.jsonb :credentials, default: {}
    end

    up_only do
      execute("UPDATE providers SET provider_type = 'vimeo', " \
              "credentials = CONCAT('{\"token\": \"', token, '\"}')::jsonb;")
    end

    change_column_null :providers, :provider_type, false
    change_column_null :providers, :credentials, false
  end
  # rubocop:enable Rails/BulkChangeTable
end
