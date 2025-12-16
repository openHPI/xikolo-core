# frozen_string_literal: true

module RestifyHelper
  DEFAULT_AUTH_HEADERS = {
    'Authorization' => "Bearer #{ENV.fetch('XIKOLO_WEB_API', nil)}",
  }.freeze

  def restify_with_headers(url)
    Restify.new(url, headers: DEFAULT_AUTH_HEADERS)
  end
end
