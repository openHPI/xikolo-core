# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Section < Node
    belongs_to :section, class_name: 'CourseService::Section'

    validates :parent_id, presence: true
    validates :section_id, uniqueness: {scope: :course_id}
  end
end
end
