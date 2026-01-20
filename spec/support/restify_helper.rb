# frozen_string_literal: true

module RestifyHelper
  DEFAULT_AUTH_HEADERS = {
    'Authorization' => "Bearer #{ENV.fetch('XIKOLO_WEB_API')}",
  }.freeze

  def restify_with_headers(url, **options)
    options[:headers] = (options[:headers] || {}).merge(DEFAULT_AUTH_HEADERS)
    Restify.new(url, **options)
  end
end
