# frozen_string_literal: true

module Global
  class CopyToClipboard < ApplicationComponent
    def initialize(text, tooltip: nil)
      @text = text
      @tooltip = tooltip
    end
  end
end
