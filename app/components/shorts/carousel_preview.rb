# frozen_string_literal: true

class Shorts::CarouselPreview < ViewComponent::Preview
  def default
    render(Shorts::Carousel.new(items: items))
  end

  def self.short_ids
    %w[8da99b7c-f9b8-4464-846f-6635924b5e5b db797666-bf28-434c-8646-af43872f23a4]
  end

  private

  def items
    [
      {
        id: '8da99b7c-f9b8-4464-846f-6635924b5e5b',
        thumbnail: 'https://vz-690a2860-9e9.b-cdn.net/8da99b7c-f9b8-4464-846f-6635924b5e5b/thumbnail.jpg',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://vz-690a2860-9e9.b-cdn.net/db797666-bf28-434c-8646-af43872f23a4/thumbnail.jpg',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://img.daisyui.com/images/stock/photo-1572635148818-ef6fd45eb394.webp',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://img.daisyui.com/images/stock/photo-1494253109108-2e30c049369b.webp',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://img.daisyui.com/images/stock/photo-1550258987-190a2d41a8ba.webp',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://img.daisyui.com/images/stock/photo-1559181567-c3190ca9959b.webp',
      },
      {
        id: 'db797666-bf28-434c-8646-af43872f23a4',
        thumbnail: 'https://img.daisyui.com/images/stock/photo-1601004890684-d8cbf643f5f2.webp',
      },
    ]
  end
end
