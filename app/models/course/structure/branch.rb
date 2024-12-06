# frozen_string_literal: true

module Course
  module Structure
    class Branch < Node
      belongs_to :branch, class_name: '::Course::Branch'

      class << self
        def preload_content!(nodes)
          ActiveRecord::Associations::Preloader.new.preload(nodes, :branch)
        end
      end
    end
  end
end