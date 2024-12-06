# frozen_string_literal: true

module Navigation
  class ProfileItem < ApplicationComponent
    def initialize(user:, gamification_score:)
      @user = user
      @gamification_score = gamification_score
    end

    include Navigation::Helpers::ProfileSubmenuHelper

    private

    def render?
      @user.logged_in?
    end

    def css_classes
      classes = %w[navigation-profile-item]
      classes << 'navigation-profile-item--masquerated' if user_instrumented
      classes.join(' ')
    end

    def active?
      submenu.any? { _1[:active] }
    end

    def active_class
      'navigation-profile-item__main--active' if active?
    end

    def user_id
      @user.id
    end

    def gamification_score
      @gamification_score if @user.feature?('gamification')
    end

    def config
      @config ||= Xikolo.config.profile
    end

    def submenu
      @submenu ||= submenu_for(@user, config)
    end

    def user_instrumented
      @user.instrumented?
    end
  end
end
