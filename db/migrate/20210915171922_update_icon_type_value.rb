# frozen_string_literal: true

class UpdateIconTypeValue < ActiveRecord::Migration[5.2]
  def up
    execute "UPDATE items SET icon_type = 'exercise2' WHERE icon_type = 'exercise';"
    execute "UPDATE items SET icon_type = 'community' WHERE icon_type = 'team_exercise';"
    execute "UPDATE items SET icon_type = 'chat' WHERE icon_type = 'discussion';"
  end

  def down
    execute "UPDATE items SET icon_type = 'exercise' WHERE icon_type = 'exercise2';"
    execute "UPDATE items SET icon_type = 'team_exercise' WHERE icon_type = 'community';"
    execute "UPDATE items SET icon_type = 'discussion' WHERE icon_type = 'chat';"
  end
end
