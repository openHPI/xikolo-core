# frozen_string_literal: true

module MarkdownHelper
  EMPTY = ''

  SANITIZE_CONFIG = Sanitize::Config.freeze_config(
    elements: %w[
      a abbr address article aside b bdi bdo blockquote body br caption cite
      code col colgroup data dd del dfn div dl dt em figcaption figure footer
      h1 h2 h3 h4 h5 h6 head header hgroup hr html i img ins kbd li main mark
      nav ol p pre q rp rt ruby s samp section small span strike strong style
      sub summary sup sup table tbody td tfoot th thead time title tr u ul
      var wbr
    ],
    attributes: {
      all: %w[class dir hidden id lang style tabindex title translate],
      'a' => %w[href target rel],
      'abbr' => %w[title],
      'blockquote' => %w[cite],
      'dfn' => %w[title],
      'q' => %w[cite],
      'time' => %w[datetime pubdate],
      'col' => %w[span width],
      'colgroup' => %w[span width],
      'data' => %w[value],
      'del' => %w[cite datetime],
      'img' => %w[align alt border height src srcset width],
      'ins' => %w[cite datetime],
      'li' => %w[value],
      'ol' => %w[reversed start type],
      'table' => %w[align bgcolor border cellpadding cellspacing frame rules sortable summary width],
      'td' => %w[abbr align axis colspan headers rowspan style valign width],
      'th' => %w[abbr align axis colspan headers rowspan scope sorted style valign width],
      'ul' => %w[type],
    },
    protocols: {
      'a' => {'href' => %w[http https mailto] + [:relative]},
      'blockquote' => {'cite' => %w[http https] + [:relative]},
      'q' => {'cite' => %w[http https] + [:relative]},
      'del' => {'cite' => %w[http https] + [:relative]},
      'img' => {'src' => %w[http https] + [:relative]},
      'ins' => {'cite' => %w[http https] + [:relative]},
    },
    css: {
      properties: Sanitize::Config::RELAXED[:css][:properties],
    }
  )

  def render_markdown(markup, include_toc: false, allow_tables: false, escape_html: true)
    return EMPTY if markup.blank?

    rendered = _render_md(
      BlankTargets.new(
        escape_html:,
        with_toc_data: include_toc,
        hard_wrap: true
      ),
      markup,
      allow_tables:
    )

    if escape_html
      Sanitize.fragment(rendered, SANITIZE_CONFIG)
    else
      rendered
    end
  end

  ##
  # Render Markdown for use in a richtext item.
  #
  # NOTE: This allows unescaped HTML in those items.
  #
  def render_rich_text_item_markdown(item)
    return EMPTY if item.text_html.blank?

    base_tracking_params = {
      tracking_type: 'rich_text_item_link',
      tracking_id: item.id,
      tracking_course_id: item.course_id,
    }

    internal_link_callback = proc do |link|
      tracking_params = base_tracking_params.merge(url: link) # to track the original url
      uri = Addressable::URI.parse(link)
      uri.query_values = uri.query_values&.merge(tracking_params) || tracking_params
      uri.to_s
    rescue Addressable::URI::InvalidURIError
      link
    end

    external_link_callback = proc do |link|
      Xikolo::Common::Tracking::ExternalLink.new(
        link,
        Xikolo.base_url,
        base_tracking_params
      ).to_s
    end

    _render_md(
      BlankTargets.new(
        {
          escape_html: false,
          with_toc_data: false,
          hard_wrap: true,
        },
        internal_link_callback,
        external_link_callback
      ),
      item.text_html,
      allow_tables: true
    )
  end

  private

  def _render_md(renderer, markup, allow_tables:)
    Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: allow_tables,
      space_after_headers: true,
      strikethrough: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_spacing: true
    ).render(markup)
  end

  class BlankTargets < Redcarpet::Render::HTML
    # rubocop:disable Rails/HelperInstanceVariable
    def initialize(params, internal_link_callback = nil, external_link_callback = nil)
      super(params)

      @internal_link_callback = internal_link_callback
      @external_link_callback = external_link_callback
    end

    def autolink(link, link_type)
      return nil if link.blank?

      href = link_type == :email ? "mailto:#{link}" : link
      %(<a class="bs-a" href="#{href}">#{link}</a>)
    end

    def link(link, title, content)
      return nil if link.blank?

      output = '<a class="bs-a"'

      if title
        output += " title=\"#{title}\""
      end

      begin
        link = normalize_link(link)
        uri = URI(link)

        if open_in_new_tab?(uri)
          if valid_callback?(uri)
            link = @external_link_callback.call(link.to_s)
          end

          # open links with external host or files in new tab
          output += ' target="_blank" rel="noopener"'
        elsif absolute_web_link?(uri) && @internal_link_callback
          link = @internal_link_callback.call(link.to_s)
        end

        output += " href=\"#{link}\""
      rescue URI::Error => e
        Rails.logger.error e.message
      end

      output + ">#{content || link}</a>"
    end

    private

    def normalize_link(link)
      return link if %r{\A[a-z][a-z0-9+.-]*://}i.match?(link)
      return "https://#{link}" if link =~ /\Awww\./i || link =~ /\A[a-z0-9.-]+\.[a-z]{2,}\z/i

      link
    end

    def absolute_web_link?(uri)
      uri.scheme && %w[http https].include?(uri.scheme)
    end

    def open_in_new_tab?(uri)
      # is external host or file
      (uri.host.present? && !Xikolo.base_url.host.casecmp(uri.host).zero?) ||
        (uri.path.present? && uri.path.start_with?('/files/'))
    end

    def valid_callback?(uri)
      (uri.scheme.nil? || absolute_web_link?(uri)) && @external_link_callback
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
