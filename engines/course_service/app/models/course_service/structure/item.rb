# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  class Item < Node
    belongs_to :item, class_name: 'CourseService::Item'

    validates :parent_id, presence: true
    validates :item_id, uniqueness: {scope: :course_id}

    class << self
      def preload_content!(nodes)
        ActiveRecord::Associations::Preloader.new(records: nodes, associations: :item).call
      end
    end
  end
end
end
