# frozen_string_literal: true

module Global
  class ActionsDropdown < ApplicationComponent
    def initialize(menu_side: 'left', text: nil, css_classes: '')
      @menu_side = menu_side
      @text = text
      @css_classes = css_classes
    end

    renders_many :actions
    renders_many :destructive_actions

    def aria_label
      I18n.t(:'components.actions_dropdown.aria_label')
    end

    def button_css_modifiers
      'actions-dropdown__button--with-text' if @text
    end

    def menu_css_modifiers
      "actions-dropdown__menu--#{@menu_side}" if %w[right left].include?(@menu_side)
    end
  end
end
