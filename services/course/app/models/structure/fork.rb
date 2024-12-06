# frozen_string_literal: true

module Structure
  class Fork < Node
    belongs_to :fork, class_name: '::Fork'

    has_one :content_test, through: :fork

    validates :parent_id, presence: true
    validates :fork_id, uniqueness: {scope: :course_id}

    validate :allowed_parents
    validate :allowed_children

    private

    def allowed_parents
      unless parent.is_a?(Structure::Section)
        errors.add :parent, 'must be a section'
      end
    end

    def allowed_children
      unless children.all?(Structure::Branch)
        errors.add :children, 'must all be branches'
      end
    end
  end
end
