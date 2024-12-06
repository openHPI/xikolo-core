# frozen_string_literal: true

module Course
  class ContentTest < ::ApplicationRecord
    belongs_to :course
    has_many :forks, dependent: :restrict_with_exception
  end
end
