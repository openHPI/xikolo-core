# frozen_string_literal: true

module Course
  class BottomNavigationPreview < ViewComponent::Preview
    def default
      render_navigation(previous_link:, next_link:)
    end

    def next_only
      render_navigation(next_link:)
    end

    def prev_only
      render_navigation(previous_link:)
    end

    private

    def render_navigation(**links)
      render ::Course::BottomBar.new do |bar|
        bar.with_navigation(component: ::Course::BottomNavigation.new(**links))
      end
    end

    def previous_link
      {url: '/learn/example/items/previous', title: 'Introduction', icon: 'video'}
    end

    def next_link
      {url: '/learn/example/items/next', title: 'Check your knowledge', icon: 'learning_material'}
    end
  end
end
