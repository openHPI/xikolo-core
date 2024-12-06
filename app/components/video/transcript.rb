# frozen_string_literal: true

module Video
  class Transcript < ApplicationComponent
    def initialize(initial_hidden_state, empty_msg: 'No data available', scroll_button_text: '')
      @initial_hidden_state = initial_hidden_state
      @empty_msg = empty_msg
      @scroll_button_text = scroll_button_text
    end
  end
end
