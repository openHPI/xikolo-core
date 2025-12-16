# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Item < Node
    belongs_to :item, class_name: 'CourseService::Item'

    validates :parent_id, presence: true
    validates :item_id, uniqueness: {scope: :course_id}
  end
end
end
