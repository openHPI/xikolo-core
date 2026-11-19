# frozen_string_literal: true

module Global
  class Breadcrumbs < ApplicationComponent
    attr_reader :items

    def initialize(items:)
      @items = items
    end

    def render?
      items.any?
    end

    def last_item?(index)
      index == items.size - 1
    end

    def truncated?
      items.size > 2
    end

    def collapsed?(index)
      truncated? && index < items.size - 2
    end
  end
end
