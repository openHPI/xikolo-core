# frozen_string_literal: true

class RichTextItemPresenter < ItemPresenter
  include MarkdownHelper

  def self.build(item, section, course, user, **)
    richtext = Course::Richtext.find(item.content_id)
    new item:, richtext:, course:, section:, user:
  end

  def text_html
    render_markdown(@richtext.text&.external, allow_tables: true, escape_html: false)
  end
end
