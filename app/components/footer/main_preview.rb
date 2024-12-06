# frozen_string_literal: true

module Footer
  class MainPreview < ViewComponent::Preview
    def complete
      render Footer::Main.new
    end
  end
end
