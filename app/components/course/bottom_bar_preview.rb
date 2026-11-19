# frozen_string_literal: true

module Course
  class BottomBarPreview < ViewComponent::Preview
    include ActionView::Helpers::FormTagHelper

    def navigation_only
      render_bar(links: {previous_link:, next_link:})
    end

    def action_only
      render_bar(actions: ['Primary action'])
    end

    def navigation_and_action
      render_bar(links: {previous_link:, next_link:}, actions: ['Primary action'])
    end

    def next_and_action
      render_bar(links: {next_link:}, actions: ['Primary action'])
    end

    def previous_and_action
      render_bar(links: {previous_link:}, actions: ['Primary action'])
    end

    def multiple_actions
      render_bar(links: {previous_link:, next_link:}, actions: ['Primary action', 'Secondary action'])
    end

    def with_long_text
      render_bar(
        links: {
          previous_link: previous_link.merge(title: 'Previous item with a long title that exceeds the available space'),
          next_link: next_link.merge(title: 'A following item with a long title that exceeds the available space'),
        },
        actions: ['A primary action with a long label that may need to wrap']
      )
    end

    private

    def render_bar(links: nil, actions: [])
      render ::Course::BottomBar.new do |bar|
        bar.with_navigation(component: ::Course::BottomNavigation.new(**links)) if links
        if actions.any?
          bar.with_primary_action do
            buttons = actions.map.with_index do |label, index|
              button_tag label, type: :button, class: "#{action_class}#{' x-btn-outline' if index.positive?}"
            end

            if actions.one?
              safe_join(buttons)
            else
              content_tag :div, safe_join(buttons), class: 'grid w-full min-w-0 grid-cols-2 items-center gap-2'
            end
          end
        end
      end
    end

    def action_class
      'x-btn x-btn-neutral w-full max-w-full rounded-2xl whitespace-normal'
    end

    def previous_link
      {url: '#', title: 'Previous item', icon: 'video'}
    end

    def next_link
      {url: '#', title: 'Next item', icon: 'learning_material'}
    end
  end
end
