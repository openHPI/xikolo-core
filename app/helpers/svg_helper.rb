# frozen_string_literal: true

module SvgHelper
  SANATIZER = Rails::HTML5::SafeListSanitizer.new
  SVG_ALLOWLIST = {
    tags: %w[svg path g rect circle],
    attributes: %w[class fill d viewBox xmlns width height],
  }.freeze

  PIXELART_ICON_PATH = Rails.root.join('app/assets/images/pixelarticons')

  def pixelart_icon(name, css_class: 'w-6 h-6')
    svg = File.read(PIXELART_ICON_PATH.join("#{name}.svg"))
    svg = svg.sub('<svg', %(<svg class="#{css_class}" fill="currentColor")) if css_class.present?
    SANATIZER.sanitize(svg, SVG_ALLOWLIST).html_safe # rubocop:disable Rails/OutputSafety
  rescue Errno::ENOENT
    raise if Rails.env.local?
  end
end
