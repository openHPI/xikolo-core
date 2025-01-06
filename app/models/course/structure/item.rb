# frozen_string_literal: true

module Course
  module Structure
    class Item < Node
      belongs_to :item, class_name: '::Course::Item'

      class << self
        def preload_content!(nodes)
          ActiveRecord::Associations::Preloader.new(records: nodes, associations: :item).call
        end
      end
    end
  end
end
