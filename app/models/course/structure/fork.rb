# frozen_string_literal: true

module Course
  module Structure
    class Fork < Node
      belongs_to :fork, class_name: '::Course::Fork'

      has_one :content_test, through: :fork

      class << self
        def preload_content!(nodes)
          ActiveRecord::Associations::Preloader.new.preload(nodes, fork: :content_test)
        end
      end
    end
  end
end
