# frozen_string_literal: true

class AddClusterIDIndexToClassifiers < ActiveRecord::Migration[5.2]
  def change
    add_index :classifiers, :cluster_id
  end
end
