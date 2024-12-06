# frozen_string_literal: true

class RemoveNegativeScoresFromCourseItems < ActiveRecord::Migration[5.2]
  def up
    execute 'UPDATE items SET max_dpoints = 0 WHERE max_dpoints < 0;'
  end
end
