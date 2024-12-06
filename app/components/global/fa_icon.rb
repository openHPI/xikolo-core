# frozen_string_literal: true

module Global
  class FaIcon < ApplicationComponent
    NAME_SEPARATOR = '+'

    def initialize(name, style: :regular, title: nil, css_classes: '')
      @name, @stack_icon = name.split(NAME_SEPARATOR)
      @style = style
      @title = title
      @css_classes = css_classes
    end

    private

    def css_classes
      "#{@stack_icon ? 'xi-icon__masked' : 'xi-icon'} fa-#{@style} fa-#{@name} #{@css_classes}"
    end

    def stack_icon_classes
      "xi-icon__stacked fa-#{@style} fa-#{@stack_icon}"
    end
  end
end
