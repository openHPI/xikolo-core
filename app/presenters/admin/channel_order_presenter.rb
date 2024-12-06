# frozen_string_literal: true

class Admin::ChannelOrderPresenter
  def initialize(channels)
    @channels = channels
  end

  def channels_order_select
    @channels.map {|channel| [channel['name'], channel['id']] }
  end
end
