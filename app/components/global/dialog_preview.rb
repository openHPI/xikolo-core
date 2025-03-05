# frozen_string_literal: true

module Global
  class DialogPreview < ViewComponent::Preview
    # The trigger for the dialog is separate from the component itself.
    # The component is initialized with an id, the id must also be added to the trigger as an aria-controls attribute,
    # as seen  in the Source tab.
    def default
      render_with_template(template: 'global/dialog_preview')
    end

    # The trigger for the dialog is separate from the component itself.
    # The component is initialized with an id, the id must also be added to the trigger as an aria-controls attribute,
    # as seen  in the Source tab.
    def with_enrollment_content
      render_with_template(template: 'global/dialog_with_enrollment_preview')
    end
  end
end
