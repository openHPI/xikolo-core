# frozen_string_literal: true

module Structure
  class Branch < Node
    belongs_to :branch, class_name: '::Branch'

    validates :parent_id, presence: true
    validates :branch_id, uniqueness: {scope: :course_id}
  end
end
