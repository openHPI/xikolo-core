# frozen_string_literal: true

module Dashboard
  module Poll
    class Widget < ApplicationComponent
      def initialize(poll)
        @poll = poll
      end
    end
  end
end
