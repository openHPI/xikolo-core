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
    Sentry.get_trace_propagation_meta.html_safe # rubocop:disable Rails/OutputSafety
  end
end
