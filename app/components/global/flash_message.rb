# frozen_string_literal: true

module Global
  class FlashMessage < ApplicationComponent
    def initialize(type, text)
      @type = type
      @text = text
    end

    private

    def icon_name
      {
        success: 'circle-check',
        error: 'circle-exclamation',
        alert: 'triangle-exclamation',
        notice: 'circle-info',
      }[@type] || ''
    end
  end
end
