# frozen_string_literal: true

class Shorts::Carousel < ApplicationComponent
  MIN_ITEMS_FOR_INFINITE_SCROLL = 3

  # @param items [Array<Hash{id: String, thumbnail: String}>]
  def initialize(items:)
    @items = items
  end

  def render?
    @items.any?
  end

  private

  def infinite_scroll?
    @items.size >= MIN_ITEMS_FOR_INFINITE_SCROLL
  end

  def carousel_items
    return @items unless infinite_scroll?

    clones = @items.map {|item| item.merge(clone: true) }
    clones + @items + clones
  end
end
