# frozen_string_literal: true

module Global
  class BreadcrumbsPreview < ViewComponent::Preview
    include SvgHelper

    def default
      items = [
        {url: '#', text: 'All discussions'},
        {url: '#', text: 'Discussion'},
        {url: '#', text: 'Discussion'},
      ]

      render Global::Breadcrumbs.new(items:)
    end

    def with_icon
      items = [
        {url: '#', icon: pixelart_icon('home', css_class: 'w-4 h-4'), aria_label: I18n.t('header.navigation.home')},
        {url: '#', text: 'Lernen'},
        {url: '#', text: 'Angebot'},
      ]

      render Global::Breadcrumbs.new(items:)
    end
  end
end
