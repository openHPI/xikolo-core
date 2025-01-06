# frozen_string_literal: true

require 'addressable/uri'

module Imagecrop
  class << self
    def transform(image_url, query_params = {})
      # Leave the URL untouched when there is no imagecrop service
      return image_url unless enabled?

      # The imagecrop service can only deal with non-SVG images
      return image_url if image_url.end_with?('.svg')

      # Do not try to optimize (and break) .ico icons
      return image_url if image_url.end_with?('.ico')

      # imagecrop needs absolute URLs, make paths relative to base_url:
      # (if join is called with an URL, the URL is returned unchanged)
      image_url = Xikolo.base_url.join(image_url).to_s

      ImgproxyWrapper.new(image_url, query_params).proxy_url
    end

    def enabled?
      imgproxy_url.present? &&
        Rails.application.secrets.imgproxy_key.present? &&
        Rails.application.secrets.imgproxy_salt.present?
    end

    def origin
      imgproxy_url.origin if enabled?
    end

    private

    def imgproxy_url
      Addressable::URI.parse(Xikolo.config.imgproxy_url).freeze
    end
  end
end
