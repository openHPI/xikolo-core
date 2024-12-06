# frozen_string_literal: true

module Home
  class TilesGroupPreview < ViewComponent::Preview
    # @!group Types

    def with_title
      render Home::TilesGroup.new(title: 'News') do |c|
        c.with_tile 'Be curious.', text: 'Learn for free - anytime and anywhere.',
          link: '/about'
        c.with_tile 'Be social.', text: 'Become part of af a vibrant, international social learning community.',
          link: '/faq'
        c.with_tile 'Be successful.', text: 'Get the latest knowledge to shape a digital future.',
          link: '/'
      end
    end

    def with_decorated_tiles
      render Home::TilesGroup.new do |c|
        c.with_tile 'Be curious.', text: 'Learn for free - anytime and anywhere.',
          link: '/about', styles: {title_decoration: true}
        c.with_tile 'Be social.', text: 'Become part of af a vibrant, international social learning community.',
          link: '/faq', styles: {title_decoration: true}
        c.with_tile 'Be successful.', text: 'Get the latest knowledge to shape a digital future.',
          link: '/', styles: {title_decoration: true}
      end
    end

    def with_image
      render Home::TilesGroup.new do |c|
        c.with_tile 'Be curious.', text: 'Learn for free - anytime and anywhere.',
          link: '/about', image: {url: 'https://picsum.photos/600/350', alt: 'Image description'}
        c.with_tile 'Be social.', text: 'Become part of af a vibrant, international social learning community.',
          link: '/faq', image: {url: 'https://picsum.photos/600/350', alt: 'Image description'}
        c.with_tile 'Be successful.', text: 'Get the latest knowledge to shape a digital future.',
          link: '/', image: {url: 'https://picsum.photos/600/350', alt: 'Image description'}
      end
    end

    # @!endgroup
  end
end
