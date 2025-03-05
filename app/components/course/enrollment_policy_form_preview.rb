# frozen_string_literal: true

module Course
  class EnrollmentPolicyFormPreview < ViewComponent::Preview
    def default
      render ::Course::EnrollmentPolicyForm.new('content-ab')
    end
  end
end
