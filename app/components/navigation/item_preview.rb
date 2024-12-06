# frozen_string_literal: true

module Navigation
  class ItemPreview < ViewComponent::Preview
    include ActionView::Helpers::UrlHelper

    # @!group
    # @display bg_color "#fafafa"
    def item
      render Navigation::Item.new(text: 'News', link: {href: '/'})
    end

    def item_selected
      render Navigation::Item.new(text: 'News', link: {href: '/'}, active: true)
    end

    def item_locked
      render Navigation::Item.new(text: 'News', link: {href: '/'}, locked: true)
    end

    def item_tooltip
      render Navigation::Item.new(text: 'News', link: {href: '/'}, tooltip: 'This is a tooltip')
    end

    def icon_and_text
      render Navigation::Item.new(
        text: 'Chapter one',
        link: {href: '/'},
        icon: {code: 'chevron-right'}
      )
    end

    def icon_only
      render Navigation::Item.new(icon: {code: 'globe', aria_label: 'Choose language'}, link: {href: '/'})
    end

    def dropdown
      render Navigation::Item.new(text: 'Channels') do |c|
        c.with_item text: 'Design Thinking', link: {href: '/'}
        c.with_item text: 'Quantum Computing', link: {href: '/'}
      end
    end

    # @label This resembels the "Language" dropdown in the navigation bar
    def dropdown_with_icon
      render Navigation::Item.new(text: 'English', icon: {code: 'globe', aria_label: 'Choose language'}) do |c|
        c.with_item text: 'Deutsch', link: {href: '/'}
        c.with_item text: 'Español', link: {href: '/'}
      end
    end

    def nested_dropdowns
      render Navigation::Item.new(text: 'Menu') do |c|
        c.with_item(text: 'Channels', link: {href: '/'}).tap do |a|
          a.with_item(text: 'Design Thinking', link: {href: '/'})
          a.with_item(text: 'Quantum Computing', link: {href: '/'})
        end
        c.with_item(text: 'English', link: {href: '/'}).tap do |b|
          b.with_item(text: 'Deutsch', link: {href: '/'})
          b.with_item(text: 'Español', link: {href: '/'})
        end
      end
    end

    # @!endgroup
  end
end
