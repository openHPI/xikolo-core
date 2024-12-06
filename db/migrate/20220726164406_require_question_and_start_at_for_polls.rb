# frozen_string_literal: true

class RequireQuestionAndStartAtForPolls < ActiveRecord::Migration[6.0]
  # rubocop:disable Rails/BulkChangeTable
  def change
    up_only do
      execute('UPDATE polls SET end_at = CURRENT_TIMESTAMP WHERE end_at IS NULL')
    end

    change_column_null :polls, :question, false
    change_column_null :polls, :end_at, false
  end
  # rubocop:enable Rails/BulkChangeTable
end
