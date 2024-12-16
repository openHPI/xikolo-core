# frozen_string_literal: true

module Course
  class EnrollmentDialogPreview < ViewComponent::Preview
    def default
      render_with_template(template: 'course/enrollment_dialog_preview')
    end
  end
end
