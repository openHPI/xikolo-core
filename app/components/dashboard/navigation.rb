# frozen_string_literal: true

module Dashboard
  class Navigation < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    include ::Navigation::Helpers::ProfileSubmenuHelper

    private

    def navigation
      @navigation ||= submenu_for(@user, config)
    end

    def config
      @config ||= Xikolo.config.profile
    end
  end
end
