# frozen_string_literal: true

class ServiceAuthorizationConstraint
  def matches?(request)
    header = request.get_header('HTTP_AUTHORIZATION')
    return false unless header&.start_with?('Bearer ')

    provided_token = header.split(' ', 2).last

    ActiveSupport::SecurityUtils.secure_compare(provided_token, internal_api_key)
  end

  private

  def internal_api_key
    ENV.fetch('XIKOLO_WEB_API')
  end
end
