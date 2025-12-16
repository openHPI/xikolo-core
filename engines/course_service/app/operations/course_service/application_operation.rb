# frozen_string_literal: true

module CourseService
class ApplicationOperation # rubocop:disable Layout/IndentationWidth
  class << self
    def call(...)
      new(...).call
    end
  end
end
end
