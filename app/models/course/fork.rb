# frozen_string_literal: true

module Course
  class Fork < ::ApplicationRecord
    has_one :node, class_name: '::Course::Structure::Fork', dependent: :destroy

    belongs_to :content_test
    belongs_to :section
    has_many :branches, dependent: :destroy
  end
end
