# frozen_string_literal: true

module NewsService
module MarkdownService # rubocop:disable Layout/IndentationWidth
  class << self
    def render_html(text)
      externalized = Xikolo::S3.externalize_file_refs(text, public: true)
      renderer.render externalized
    end

    private

    def renderer
      @renderer ||= Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(
          no_images: false,
          no_links: false,
          filter_html: true
        ),
        autolink: true,
        space_after_headers: true,
        strikethrough: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        lax_spacing: true
      )
    end
  end
end
end
