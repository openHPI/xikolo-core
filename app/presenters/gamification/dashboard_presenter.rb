# frozen_string_literal: true

module Gamification
  class DashboardPresenter
    # @param user [Account::User]
    def initialize(user)
      @user = user
    end

    def badges
      @badges ||= begin
        gained = @user.gamification_badges
          .unscope(:order)
          .group(:name, :user_id, :course_id)
          .select('COUNT(id), name, user_id, course_id, MAX(level) as level')
          .to_a

        missing = Badge.types.keys - gained.map(&:name)

        gained + missing.map do |name|
          Badge.new(name:, user: @user, level: Badge.types[name]['levels'].keys.first)
        end
      end
    end

    def scores
      @scores ||= Gamification::ScoresPresenter.new(@user)
    end
  end
end
