# frozen_string_literal: true

class Home::Channel::List < ApplicationComponent
  # @param items [Array<Channel>]
  def initialize(items:)
    @items = items
  end

  def localized_text(title)
    Translations.new(title).to_s
  end

  def render?
    @items.any?
  end
end
