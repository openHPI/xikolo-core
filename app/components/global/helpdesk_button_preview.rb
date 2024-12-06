# frozen_string_literal: true

module Global
  class HelpdeskButtonPreview < ViewComponent::Preview
    def default
      render Global::HelpdeskButton.new(user:)
    end

    def prototype_two
      render Global::HelpdeskButton.new(user: user_with_prototype_two)
    end

    private

    def user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user' => {'anonymous' => true},
      })
    end

    def user_with_prototype_two
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user' => {'anonymous' => true},
        'features' => {'chatbot.prototype-2' => true},
      })
    end
  end
end
