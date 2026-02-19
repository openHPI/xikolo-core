# frozen_string_literal: true

module Global
  class HelpdeskButton < ApplicationComponent
    def initialize(user:)
      @user = user
    end
  end
end
