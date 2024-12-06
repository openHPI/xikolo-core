# frozen_string_literal: true

module ContentSecurityPolicy
  extend ActiveSupport::Concern

  included do
    after_action :set_csp_headers
    after_action :set_rp_headers
  end
  def set_csp_headers
    return unless Xikolo.config.csp['enabled']

    asset_host = Rails.application.config.action_controller.asset_host

    # We explicitly need quotes around special keywords here as they are part of
    # the CSP protocol.
    #
    # rubocop:disable Lint/PercentStringArray
    csp_headers = {
      'default-src': %w['self'],
      'base-uri':    %w['self'],
      'script-src':  %W['self' 'unsafe-inline' 'unsafe-eval' #{asset_host}] + Xikolo.config.csp['script'],
      'style-src':   %W['self' 'unsafe-inline' #{asset_host}] + Xikolo.config.csp['style'],
      'img-src':     %w[* data:],
      'media-src':   %w['self' *.vimeocdn.com *.vimeo.com *.akamaized.net] + Xikolo.config.csp['media'],
      'frame-src':   %w['self'] + Xikolo.config.csp['frame'],
      'font-src':    %W['self' data: #{asset_host}] + Xikolo.config.csp['font'],
      'connect-src': %w['self'] + Xikolo.config.csp['connect'],
      'object-src':  %w['none'],
    }
    # rubocop:enable Lint/PercentStringArray

    if Xikolo.config.csp['report_uri']
      csp_headers[:'report-uri'] = [Xikolo.config.csp['report_uri']]
    end

    header_key = if Xikolo.config.csp['report_only'] && Xikolo.config.csp['report_uri']
                   'Content-Security-Policy-Report-Only'
                 else
                   'Content-Security-Policy'
                 end

    response.headers[header_key] = csp_headers.map {|k, v| "#{k} #{v.join(' ')}" }
      .join('; ')
  end

  def set_rp_headers
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
  end
end
