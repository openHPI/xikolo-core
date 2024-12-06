# frozen_string_literal: true

module Course
  class Popover < ApplicationComponent
    include ActionController::Cookies

    def initialize(text, target_id, cookie_name: nil)
      @text = text
      @target_id = target_id
      @cookie_name = cookie_name
    end

    def render?
      return true unless @cookie_name

      # When a popover has been dismissed, a cookie such as "hide_xyz" is set.
      # If the cookie is set, i.e. its value is "true", don't render.
      cookies[@cookie_name] != 'true'
    end
  end
end
