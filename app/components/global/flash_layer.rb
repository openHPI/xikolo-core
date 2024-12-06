# frozen_string_literal: true

module Global
  class FlashLayer < ApplicationComponent
    def initialize(type, text)
      @type = type
      @text = text
    end

    private

    def swal_options
      title, text = @text.split('<br />', 2)
      type = @type.to_s.split('_').first
      {title:, text:, type:, showCancelButton: false}
    end
  end
end
