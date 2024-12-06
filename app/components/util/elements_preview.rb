# frozen_string_literal: true

module Util
  class ElementsPreview < ViewComponent::Preview
    def buttons
      render Util::Elements.new
    end
  end
end
