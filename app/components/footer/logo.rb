# frozen_string_literal: true

module Footer
  class Logo < ApplicationComponent
    def initialize(filename, alt:, href:)
      @filename = filename
      @alt = alt
      @href = href
    end

    private

    def render?
      # Skip logo if no proper file name has been provided
      @filename.present?
    end

    def link?
      @href.present?
    end

    def path
      Imagecrop.transform(
        helpers.image_path("footer/logos/#{@filename}"),
        height: 150
      )
    end
  end
end
