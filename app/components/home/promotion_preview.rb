# frozen_string_literal: true

module Home
  class PromotionPreview < ViewComponent::Preview
    # @!group Color Background
    def default
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text'
      )
    end

    def with_link
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/'
      )
    end

    def color_variant_black
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        target: 'blank',
        variant: :black
      )
    end

    def color_variant_primary
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        target: 'blank',
        variant: :primary
      )
    end

    def color_variant_tertiary
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :tertiary
      )
    end

    # @!endgroup
    # @!group With Image
    def default_image_black
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        variant: :black,
        image_url: 'https://picsum.photos/900/350'
      )
    end

    def with_link_and_image_primary
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :primary,
        image_url: 'https://picsum.photos/900/350'
      )
    end

    def with_link_and_image_secondary
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :secondary,
        image_url: 'https://picsum.photos/900/350'
      )
    end

    def with_link_and_image_tertiary
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :tertiary,
        image_url: 'https://picsum.photos/900/350'
      )
    end

    # @!endgroup
    # @!group With Image Overlay Opacity 0-3
    def default_image_black_opacity_03
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        variant: :black,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.3
      )
    end

    def with_link_and_image_primary_opacity_03
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :primary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.3
      )
    end

    def with_link_and_image_secondary_opacity_03
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :secondary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.3
      )
    end

    def with_link_and_image_tertiary_opacity_03
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :tertiary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.3
      )
    end

    # @!endgroup
    # @!group With Image Overlay Opacity 0-7
    def default_image_black_opacity_7
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        variant: :black,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.7
      )
    end

    def with_link_and_image_primary_opacity_07
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :primary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.7
      )
    end

    def with_link_and_image_secondary_opacity_07
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :secondary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.7
      )
    end

    def with_link_and_image_tertiary_opacity_07
      render Home::Promotion.new(
        'Interesting title',
        'The basic promotion has some text The basic promotion has some text',
        link_url: '/',
        variant: :tertiary,
        image_url: 'https://picsum.photos/900/350',
        overlay_opacity: 0.7
      )
    end
    # @!endgroup
  end
end
