# frozen_string_literal: true

class ServiceAuthorizationConstraint
  def initialize(token = ENV.fetch('XIKOLO_WEB_API', nil))
    @token = token
  end

  def matches?(request)
    header = request.get_header('HTTP_AUTHORIZATION')
    return false unless header&.start_with?('Bearer ')

    provided_token = header.split(' ', 2).last

    ActiveSupport::SecurityUtils.secure_compare(provided_token, @token) # replace with @token in production
  end
end
