# frozen_string_literal: true

module NewsService
class ApplicationOperation # rubocop:disable Layout/IndentationWidth
  class << self
    def call(...)
      new(...).call
    end
  end
end
end
