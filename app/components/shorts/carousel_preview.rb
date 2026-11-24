# frozen_string_literal: true

class Shorts::CarouselPreview < ViewComponent::Preview
  def default
    render(Shorts::Carousel.new(items: Shorts::DemoMedia.items))
  end
end
