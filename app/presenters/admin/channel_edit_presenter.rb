# frozen_string_literal: true

class Admin::ChannelEditPresenter
  def initialize(form: nil, channel: nil)
    @channel = channel || {}
    if form
      @form = form
    elsif channel
      @form = Admin::ChannelForm.from_resource channel
    else
      @form = Admin::ChannelForm.new
    end
  end

  def to_model
    @form
  end

  def logo_url
    @channel['logo_url']
  end

  def stage_visual_url
    @channel['stage_visual_url']
  end

  def mobile_visual_url
    @channel['mobile_visual_url']
  end
end
