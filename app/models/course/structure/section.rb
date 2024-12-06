# frozen_string_literal: true

module Course
  module Structure
    class Section < Node
      belongs_to :section, class_name: '::Course::Section'

      class << self
        def preload_content!(nodes)
          ActiveRecord::Associations::Preloader.new.preload(nodes, :section)
        end
      end
    end
  end
end
