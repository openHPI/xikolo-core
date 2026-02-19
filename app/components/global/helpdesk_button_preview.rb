# frozen_string_literal: true

module Global
  class HelpdeskButtonPreview < ViewComponent::Preview
    def default
      render Global::HelpdeskButton.new(user:)
    end

    private

    def user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user' => {'anonymous' => true},
      })
    end
  end
end
