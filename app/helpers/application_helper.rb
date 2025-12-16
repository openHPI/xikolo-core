# frozen_string_literal: true

module ApplicationHelper
  def browser_support
    @browser_support ||= BrowserSupport.new(browser)
  end

  def hide_browser_warning?
    @in_app || cookies[:_browser_warning] == 'hide' # rubocop:disable Rails/HelperInstanceVariable
  end

  def imagecrop(image_url, query_params = {})
    Imagecrop.transform(
      image_path(image_url),
      query_params
    )
  end

  def sentry_meta_tags
    tags = Sentry.get_trace_propagation_meta

    if ENV['SENTRY_DSN_FRONTEND'].present?
      tags += tag.meta(name: 'sentry-dsn', content: ENV['SENTRY_DSN_FRONTEND'])
      env = ENV['SENTRY_ENVIRONMENT'].presence || Rails.env
      tags += tag.meta(name: 'sentry-environment', content: env)
    end

    tags.html_safe # rubocop:disable Rails/OutputSafety
  end
end
