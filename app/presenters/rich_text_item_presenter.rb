# frozen_string_literal: true

class RichTextItemPresenter < ItemPresenter
  include MarkdownHelper

  def self.build(item, course, user, **)
    richtext = CourseService::Richtext.find(item['content_id'])
    new item:, richtext:, course:, user:
  end

  def text_html
    render_markdown(@richtext.text&.external, allow_tables: true, escape_html: false)
  end

  def reading_material_download
    url = @richtext.reading_material_url
    return if url.blank?

    {
      title: I18n.t(:'items.show.rich_text.download.reading_material'),
      url:,
      file_type: File.extname(url).delete_prefix('.').presence,
    }
  end
end
