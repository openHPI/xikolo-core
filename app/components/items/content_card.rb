# frozen_string_literal: true

module Items
  class ContentCard < ApplicationComponent
    def initialize(rendered_content:, lang:, title: nil)
      @rendered_content = rendered_content
      @lang = lang
      @title = title
    end
  end
end
