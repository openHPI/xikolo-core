# frozen_string_literal: true

module Structure
  class Root < Node
    validates :course_id, uniqueness: true
  end
end
