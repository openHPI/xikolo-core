# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Branch < Node
    belongs_to :branch, class_name: 'CourseService::Branch'

    validates :parent_id, presence: true
    validates :branch_id, uniqueness: {scope: :course_id}

    class << self
      def preload_content!(nodes)
        ActiveRecord::Associations::Preloader.new(records: nodes, associations: :branch).call
      end
    end
  end
end
end
