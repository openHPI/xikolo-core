# frozen_string_literal: true

class Shorts::DeckPreview < ViewComponent::Preview
  # @display bg_color "var(--color-secondary)"
  def default
    render(Shorts::Deck.new(items: Shorts::DemoMedia.items))
  end
end
