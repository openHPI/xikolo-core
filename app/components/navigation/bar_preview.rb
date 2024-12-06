# frozen_string_literal: true

module Navigation
  class BarPreview < ViewComponent::Preview
    def default
      # For a simpler test setup, we do not allow
      # components that require further configuration

      reduced_component_set = %w[
        about
        administration
        announcements
        courses
        courses_megamenu
        home
        register
      ].freeze

      render Navigation::Bar.new(user:, allowed: reduced_component_set)
    end

    private

    def user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user' => {'anonymous' => true},
      })
    end
  end
end
