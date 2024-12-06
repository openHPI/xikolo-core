# frozen_string_literal: true

class ApplicationOperation
  class << self
    def call(...)
      new(...).call
    end
  end
end
