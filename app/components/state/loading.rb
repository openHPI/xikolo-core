# frozen_string_literal: true

module State
  class Loading < ApplicationComponent
    def initialize(text = nil)
      @text = text
    end
  end
end
