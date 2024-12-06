# frozen_string_literal: true

require 'addressable/uri'

module Login
  # Returns the appropriate login URL, depending on the current request
  # context and if external login with portal mode is enabled or not.
  def login_url
    if Login.external?
      external_login_url
    else
      new_session_url
    end
  end

  def external_login_url
    url = Xikolo.config.portal_mode&.dig('external_login', 'url')
    raise TypeError if url.blank?

    Addressable::URI.parse(url).to_s
  rescue Addressable::URI::InvalidURIError, TypeError
    raise Status::Redirect.new('Invalid external login URL', root_url)
  end

  class << self
    def external?
      Xikolo.config.portal_mode&.dig('external_login', 'enabled')
    end
  end
end
