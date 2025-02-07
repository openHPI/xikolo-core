# frozen_string_literal: true

if Rails.env.integration?
  require 'webmock'
  require 'omniauth'

  require_relative 'integration_video'
  require_relative '../seeds/video'

  XiIntegration.hook :test_setup do
    Rails.logger.debug 'Clearing rails cache'
    Rails.cache.clear
    XiIntegration::Seeds::Video.seed!
  end

  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock :saml,
    provider: 'saml',
    uid: '1234567',
    info: {
      name: 'Lassie Fairy',
      email: 'lassie@company.com',
    },
    credentials: {},
    extra: {}

  WebMock.enable!
  WebMock.disable_net_connect!(
    allow: /s3\.openhpicloud\.de/,
    allow_localhost: true,
    net_http_connect_on_start: true
  )

  XiIntegration::Video.install
end
