# frozen_string_literal: true

class Navigation::Tabs < ViewComponent::Base
  renders_many :tabs, ->(controls: nil, active: false, &block) do
    if controls.present?
      tag.li(class: "navigation-tabs__item #{'navigation-tabs__item--active' if active}",
        role: 'tab') do
        tag.button(
          type: 'button',
          class: 'navigation-tabs__button',
          'aria-controls': controls,
          &block
        )
      end
    else
      tag.li(class: "navigation-tabs__item #{'navigation-tabs__item--active' if active}",
      role: 'tab', &block)
    end
  end

  renders_many :additional_items

  renders_many :panels, ->(id: nil, active: false, &block) do
    tag.div(
      role: 'tabpanel',
      'data-id': id,
      hidden: !active,
      &block
    )
  end

  def initialize(collapsible: false)
    @collapsible = collapsible
    @content_id = SecureRandom.uuid
  end

  def css_classes
    classes = ['navigation-tabs__content']
    classes << 'navigation-tabs__content--collapsible' if @collapsible
    classes.compact.join(' ')
  end
end
