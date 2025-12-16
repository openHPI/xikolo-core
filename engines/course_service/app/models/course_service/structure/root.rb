# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Root < Node
    validates :course_id, uniqueness: true
  end
end
end
