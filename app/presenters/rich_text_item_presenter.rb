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

  def default_icon
    'file-lines'
  end

  def icon_mapping
    {
      exercise2: 'keyboard',
      youtube: 'video+circle-arrow-up-right',
      moderator: 'microphone-lines',
      assistant: 'head-side-headphones',
      external_video: 'video+circle-arrow-up-right',
      community: 'users',
      chart: 'chart-column',
      chat: 'comments',
    }.freeze
  end

  def icon
    return default_icon unless icon_type

    icon_mapping.fetch(icon_type.to_sym, default_icon)
  end

  def icon_type
    @item['icon_type']
  end
end
