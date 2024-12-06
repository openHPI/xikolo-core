# frozen_string_literal: true

module Home
  class Category < ApplicationComponent
    def initialize(category, title: category.title, teaser: nil)
      @category = category
      @title = title
      @teaser = teaser
    end
  end
end
