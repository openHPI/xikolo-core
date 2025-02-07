# frozen_string_literal: true

##
# Loads and caches the available channels.
#
# The +course_channels+ helper method can be used to access the list in
# controllers and views.
#
module LoadsCourseChannels
  extend ActiveSupport::Concern

  included do
    helper_method :course_channels
  end

  CHANNELS_PUBLIC_CACHE_KEY = 'web/channels/public/v2'

  def course_channels
    @course_channels ||= Rails.cache.fetch(CHANNELS_PUBLIC_CACHE_KEY, expires_in: 1.hour) do
      Course::Channel
        .order(:position, :code)
        .where(public: true, affiliated: false, archived: false)
        .to_a
    end
  end
end
