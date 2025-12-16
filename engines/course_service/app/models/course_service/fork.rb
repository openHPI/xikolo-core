# frozen_string_literal: true

module CourseService
class Fork < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :forks

  belongs_to :content_test
  belongs_to :section
  has_many :branches, dependent: :destroy

  has_one :node, class_name: 'CourseService::Structure::Fork', dependent: :destroy

  # Run in same transaction as creation
  after_create :attach_node
  after_create :create_branches

  private

  def attach_node
    create_node!(course: section.course, parent: section.node)
  end

  def create_branches
    content_test.with_groups do |identifier, group|
      branches.create!(group:, title: "#{title} - #{identifier}")
    end
  end
end
end
