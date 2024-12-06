# frozen_string_literal: true

module Global
  class AccordionPreview < ViewComponent::Preview
    def default
      render_with_template
    end

    def expanded
      render_with_template
    end
  end
end
