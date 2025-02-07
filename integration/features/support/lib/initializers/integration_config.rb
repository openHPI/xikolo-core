# frozen_string_literal: true

if Rails.env.integration?
  require 'webmock'

  include WebMock::API # rubocop:disable Style/MixinUsage

  Rack::Remote.register :set_xikolo_config do |params, _env, _request|
    Rails.logger.warn "set xikolo config name=#{params['name']}, value=#{params['value']}"
    Xikolo.config.send :"#{params['name']}=", params.fetch('value')
  end

  XiIntegration.hook :test_setup do
    Xikolo::Config.reload
  end

  # Register a remote method to stub reCAPTCHA v3
  Rack::Remote.register :stub_recaptcha_v3 do |_params, _env, _request|
    stub_request(:get, 'https://www.recaptcha.net/recaptcha/api/siteverify')
      .with(query: hash_including({
        response: /.*/,
        secret: '6Lfz8GIqAAAAAI7luM866NJN5rdPx70hJDO2tsO3',
      }))
      .to_return(status: 200, body: JSON.dump({success: true, action: 'helpdesk', score: 0.9}),
        headers: {'Content-Type' => 'application/json'})
  end

  # Register a remote method to test reCAPTCHA v2
  Rack::Remote.register :stub_recaptcha_v2 do |_params, _env, _request|
    # Stub reCAPTCHA v3 response: Simulates a low-score for a failure scenario.
    stub_request(:get, 'https://www.recaptcha.net/recaptcha/api/siteverify')
      .with(query: hash_including({
        response: /.*/,
        secret: '6Lfz8GIqAAAAAI7luM866NJN5rdPx70hJDO2tsO3',
      }))
      .to_return(status: 200, body: JSON.dump({success: true, action: 'helpdesk', score: 0.1}),
        headers: {'Content-Type' => 'application/json'})

    # Stub reCAPTCHA v2 response: Simulates a successful verification
    stub_request(:get, 'https://www.recaptcha.net/recaptcha/api/siteverify')
      .with(query: hash_including({
        response: '329iorjwea' * 20,
        secret: '6Ld08WIqAAAAAMmBrtQ1_InW6wu0WOlquOcR2GR6',
      }))
      .to_return(status: 200, body: JSON.dump({success: true}),
        headers: {'Content-Type' => 'application/json'})
  end

  Rack::Remote.register :reset_stubs do |_params, _env, _request|
    WebMock.reset!
  end
end
