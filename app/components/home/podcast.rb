# frozen_string_literal: true

module Home
  class Podcast < ApplicationComponent
    def initialize(title, podcasts: [], call_to_action: {})
      @title = title
      @podcasts = podcasts
      @call_to_action = call_to_action
    end
  end
end
