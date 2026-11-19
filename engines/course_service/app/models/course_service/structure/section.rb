# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Section < Node
    belongs_to :section, class_name: 'CourseService::Section'

    validates :parent_id, presence: true
    validates :section_id, uniqueness: {scope: :course_id}

    class << self
      def preload_content!(nodes)
        ActiveRecord::Associations::Preloader.new(records: nodes, associations: :section).call
      end
    end
  end
end
end
