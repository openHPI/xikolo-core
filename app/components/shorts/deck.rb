# frozen_string_literal: true

class Shorts::Deck < ApplicationComponent
  # @param items [Array<Hash{id: String, thumbnail: String}>]
  def initialize(items:)
    @items = items
  end

  def render?
    @items.any?
  end
end
