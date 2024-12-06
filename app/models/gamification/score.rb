# frozen_string_literal: true

module Gamification
  class Score < ::ApplicationRecord
    belongs_to :user, class_name: 'Account::User'
    belongs_to :course, class_name: 'Course::Course'

    validates :rule, presence: true
    validates :checksum, uniqueness: {scope: :rule}

    serialize :data

    after_create :update_user_badges!

    class << self
      def total
        sum(:points)
      end
    end

    private

    # Calculate and create/update all badges for this score's user.
    #
    # Badges are awarded based on the number of scores in a category, so every
    # new score may cause a new badge (level) to be awarded.
    def update_user_badges!
      Badge.types.each do |name, config|
        scores = Score.where(user_id:, rule: config['rules'])
        grouped_scores = if config['scope'] == 'course'
                           scores.group(:course_id).count
                         else
                           {nil => scores.count}
                         end

        grouped_scores.each do |course_id, count|
          ensure_badge_for_level!(name, config['levels'], count, course_id)
        end
      end
    end

    def ensure_badge_for_level!(name, levels, count, course_id = nil)
      highest_threshold = levels.values.select { count >= _1 }.max
      return if highest_threshold.nil?

      begin
        Badge.where(
          user_id:,
          name:,
          level: levels.key(highest_threshold),
          course_id:
        ).first_or_create!
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
