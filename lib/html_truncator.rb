# frozen_string_literal: true

class HtmlTruncator
  require 'truncato'
  require 'nokogiri/html5'

  ALLOWED_TAGS = %w[br em hr p strong].freeze
  ALLOWED_ATTRIBUTES = %w[class id].freeze
  DEFAULT_TRUNCATO_OPTIONS = {
    max_length: 200,
    count_tags: false,
    count_tail: true,
  }.freeze

  def initialize(**options)
    @options = options
  end

  def truncate(html, **options)
    # Truncato takes care of HTML-aware truncation.
    # For example, it also adds closing tags when they are missing.

    sanitize_opts = options.extract!(:tags)

    Truncato.truncate \
      sanitize(html, **sanitize_opts),
      DEFAULT_TRUNCATO_OPTIONS.merge(options.except(:strip_lists))
  end

  private

  def sanitizer
    # Use Rails' default sanitizer, also used in
    # the ActionView::Helpers::SanitizeHelper. It only permits a list
    # of defined tags and attributes (see #sanitized_html).
    @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
  end

  def sanitize(html, **opts)
    # Properly sanitize the HTML, only allow specified tags/attributes.
    html = strip_lists! html if @options[:strip_lists]

    sanitizer.sanitize \
      html,
      tags: opts.fetch(:tags, ALLOWED_TAGS),
      attributes: ALLOWED_ATTRIBUTES
  end

  def strip_lists!(html)
    content = Nokogiri::HTML5.fragment html
    content.search('ul > li', 'ol > li').each do |li|
      next unless li.element?

      li.replace("#{li.content}<br/>")
    end
    content.to_html
  end
end
