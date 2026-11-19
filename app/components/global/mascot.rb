# frozen_string_literal: true

module Global
  class Mascot < ApplicationComponent
    def initialize(message:)
      @message = message
    end
  end
end
