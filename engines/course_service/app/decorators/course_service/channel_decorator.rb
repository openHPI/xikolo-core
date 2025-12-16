# frozen_string_literal: true

module CourseService
class ChannelDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_api_v1(opts)
    fields(opts).merge url: h.channel_path(self)
  end

  def as_event(opts = {})
    fields(opts).as_json
  end

  def title
    Translations.new(title_translations).to_s
  end

  private

  def fields(_opts)
    {
      id:,
      code:,
      title:,
      title_translations:,
      logo_url:,
      description:,
      stage_visual_url:,
      mobile_visual_url:,
      stage_statement:,
      public:,
      highlight:,
      affiliated:,
      position:,
      info_link:,
    }
  end
end
end
