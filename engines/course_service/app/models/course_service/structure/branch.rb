# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Branch < Node
    belongs_to :branch, class_name: 'CourseService::Branch'

    validates :parent_id, presence: true
    validates :branch_id, uniqueness: {scope: :course_id}
  end
end
end
