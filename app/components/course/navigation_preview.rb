# frozen_string_literal: true

module Course
  class NavigationPreview < ViewComponent::Preview
    def enrolled(active: :details)
      render_in_header(active: active.to_sym)
    end

    def with_unread_announcements
      render_in_header(active: :details, unread_announcements: 2)
    end

    def not_enrolled
      render_in_header(active: :details, locked: true)
    end

    def without_forum
      render_in_header(active: :progress, forum: false)
    end

    private

    def render_in_header(**navigation)
      render_with_template(template: 'course/navigation_preview/in_header', locals: {navigation:})
    end
  end
end
