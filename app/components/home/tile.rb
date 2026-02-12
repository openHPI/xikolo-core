# frozen_string_literal: true

module Home
  class Tile < ApplicationComponent
    def initialize(title, text: nil, link: nil, image: {}, styles: {})
      @title = title
      @text = text
      @link = link
      @image = image
      @styles = styles
    end

    private

    def css_modifiers
      [].tap do |modifiers|
        modifiers << 'tile--with-image' if image
        modifiers << 'tile--with-decoration' if @styles[:title_decoration]
        modifiers << "tile--#{@styles[:size]}" if @styles[:size] && (%w[s m].include? @styles[:size])
      end.join(' ')
    end

    def link
      return if @link.blank?

      {
        url: @link.is_a?(Hash) ? @link[:url] : @link,
        text: @link.is_a?(Hash) ? @link[:text] : I18n.t(:'home.tile.more'),
      }
    end

    def image
      return if @image[:url].blank? || @image[:alt].blank?

      {
        url: @image[:url],
        alt: @image[:alt],
      }
    end

    def srcset
      return if @image[:url].blank?

      ext = File.extname @image[:url]
      img_2x = @image[:url].gsub(ext, ".2x#{ext}")

      return if Rails.application.assets.load_path.find(img_2x).blank?

      "#{image_path(@image[:url])}, #{image_path(img_2x)} 2x"
    end
  end
end
