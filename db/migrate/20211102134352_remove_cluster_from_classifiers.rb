# frozen_string_literal: true

class RemoveClusterFromClassifiers < ActiveRecord::Migration[5.2]
  def change
    remove_index :classifiers, :cluster
    remove_column :classifiers, :cluster, :string
  end
end
