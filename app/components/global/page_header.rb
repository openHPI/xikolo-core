# frozen_string_literal: true

module Global
  class PageHeader < ApplicationComponent
    def initialize(title, lang: nil, type: nil, subtitle: nil)
      @title = title
      @lang = lang
      @type = type
      @subtitle = subtitle
    end

    renders_one :pill, Pill

    private

    def css_modifier
      'pages-header--slim' if @type == :slim
    end
  end
end
