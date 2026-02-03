# frozen_string_literal: true

module State
  # @label Loading state
  class LoadingPreview < ViewComponent::Preview
    def plain
      render State::Loading.new
    end

    # @param text text
    def with_text(text: 'Filtering courses')
      render State::Loading.new(text)
    end
  end
end
