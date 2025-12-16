# frozen_string_literal: true

module CourseService
class Branch < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :branches

  belongs_to :group, class_name: 'CourseService::Duplicated::Group'
  belongs_to :fork

  has_one :node, class_name: 'CourseService::Structure::Branch', dependent: :destroy

  after_create :attach_node

  private

  def attach_node
    create_node!(course: fork.section.course, parent: fork.node)
  end
end
end
