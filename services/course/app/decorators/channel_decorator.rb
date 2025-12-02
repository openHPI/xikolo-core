# frozen_string_literal: true

class ChannelDecorator < ApplicationDecorator
  delegate_all

  def as_api_v1(opts)
    fields(opts).merge url: h.channel_path(self)
  end

  def as_event(opts = {})
    fields(opts).as_json
  end

  private

  def fields(_opts)
    {
      id:,
      code:,
      name:,
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
