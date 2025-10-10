# frozen_string_literal: true

class Branch < ApplicationRecord
  self.table_name = :branches

  belongs_to :group, class_name: '::Duplicated::Group'
  belongs_to :fork

  has_one :node, class_name: '::Structure::Branch', dependent: :destroy

  after_create :attach_node

  private

  def attach_node
    create_node!(course: fork.section.course, parent: fork.node)
  end
end
