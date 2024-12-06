# frozen_string_literal: true

module Home
  class TilePreview < ViewComponent::Preview
    # @!group Types

    def simple
      render Home::Tile.new('Simple tile')
    end

    def with_text
      render Home::Tile.new(
        'Tile title',
        text: 'Tile text. Neither the title nor the text will truncate although we recomend not to exceed the 3 lines'
      )
    end

    def m_size
      render Home::Tile.new(
        'Tile title',
        text: 'Tile text. Neither the title nor the text will truncate although we recomend not to exceed the 3 lines',
        styles: {title_decoration: true, size: 'm'}
      )
    end

    def with_link
      render Home::Tile.new(
        'Tile with a link',
        text: 'You can optionally link to a custom url. The default text of the link is "More"',
        link: '/about'
      )
    end

    def with_customized_text_link
      render Home::Tile.new(
        'Tile with a link',
        text: 'You can optionally link to a custom url with a custom link text.',
        link: {text: 'More courses', url: '/'}
      )
    end

    # You can optionally display an image in the tile. It will be displayed on the left side of the text
    # if there is enough space and above the text when the component has less space. The image will have a height of
    # 350px in the former layout and 200px in the latter. Make sure to optimize the size of the used image so its
    # height is not larger than 350px. If needed, the image will be zoomed to cover its container. This
    # container will be a third part of the whole tile's width in its wider variant. Don't forget an appropiate alt
    # attribute for the image, otherwise it won't display. For retina displays, you can provide the same image
    # adding .2x before the extension (e.g. image.2x.png).
    #
    # @label Tile with image
    def with_image
      render Home::Tile.new(
        'Tile with an image',
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore
          et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
          ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
          fugiat nulla pariatur. Quam pellentesque nec nam aliquam sem et tortor. Id nibh tortor id aliquet lectus
          proin. Lorem ipsum dolor sit amet consectetur adipiscing. Diam sit amet nisl suscipit adipiscing. Dignissim
          suspendisse in est ante in nibh mauris cursus. Pretium quam vulputate dignissim suspendisse in.',
        link: '/',
        image: {url: 'https://picsum.photos/600/350', alt: 'Image description'}
      )
    end

    def with_title_decoration
      render Home::Tile.new(
        'Tile with a decoration line',
        text: 'You can optionally have a decorative line next to the title that uses the primary color of the brand.',
        link: '/',
        styles: {title_decoration: true}
      )
    end

    # @!endgroup
  end
end
