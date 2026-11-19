# frozen_string_literal: true

module Form
  class PasswordFieldPreview < ViewComponent::Preview
    # @!group

    # The field on its own, as rendered by the component.
    def default
      render_with_template
    end

    # Labels and error messages stay with the form, since they differ per page.
    def labeled
      render_with_template
    end
    # @!endgroup
  end
end
