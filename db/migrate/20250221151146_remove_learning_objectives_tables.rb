# frozen_string_literal: true

class RemoveLearningObjectivesTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :user_objectives if table_exists?(:user_objectives)
    drop_table :knowledge_acquisitions if table_exists?(:knowledge_acquisitions)
    drop_table :knowledge_examinations if table_exists?(:knowledge_examinations)
    drop_table :objectives_items if table_exists?(:objectives_items)
    drop_table :learning_units if table_exists?(:learning_units)
    drop_table :objectives if table_exists?(:objectives)
  end
end
