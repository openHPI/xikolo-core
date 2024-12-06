# frozen_string_literal: true

module Structure
  class Section < Node
    belongs_to :section, class_name: '::Section'

    validates :parent_id, presence: true
    validates :section_id, uniqueness: {scope: :course_id}
  end
end
