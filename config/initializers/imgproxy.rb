# frozen_string_literal: true

class AddressableAdapter
  # `applicable?` checks if the adapter can extract
  # source URL from the provided object
  def applicable?(item)
    item.is_a? Addressable::URI
  end

  # `url` extracts source URL from the provided object
  def url(item)
    item.to_s
  end
end

if Xikolo.config.imgproxy_url
  Imgproxy.configure do |config|
    # Full URL to where imgproxy lives
    config.endpoint = Xikolo.config.imgproxy_url
    # Hex-encoded signature key and salt
    config.key = Rails.application.secrets.imgproxy_key
    config.salt = Rails.application.secrets.imgproxy_salt
    # Add URL adapter for Addressable
    config.url_adapters.add(AddressableAdapter.new)
  end
end
