# frozen_string_literal: true

module Course
  module Structure
    class Fork < Node
      belongs_to :fork, class_name: '::Course::Fork'

      has_one :content_test, through: :fork

      class << self
        def preload_content!(nodes)
          ActiveRecord::Associations::Preloader.new(records: nodes, associations: :content_test).call
        end
      end
    end
  end
end
