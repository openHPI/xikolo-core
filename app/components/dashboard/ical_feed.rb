# frozen_string_literal: true

module Dashboard
  include IcalHelper

  class IcalFeed < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    def render?
      @user.feature?('ical_feed')
    end

    def url
      helpers.ical_url(@user, full_path: true)
    end
  end
end
