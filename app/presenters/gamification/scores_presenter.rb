# frozen_string_literal: true

module Gamification
  class ScoresPresenter
    # @param user [Account::User]
    def initialize(user)
      @user = user
    end

    def any?
      by_course.count > 1
    end

    def columns
      @columns ||= [*CATEGORIES.keys, :total]
    end

    def by_course
      @by_course ||= @user.gamification_scores
        .where(rule: CATEGORIES.values.flatten).where('points > 0')
        .group(:course_id, :rule).total
        .then { sum_per_category(it) }
        .then { sum_total_per_category(it) }
        .then { load_courses(it) }
    end

    private

    CATEGORIES = {
      selftests: %i[selftest_master take_selftest],
      communication: %i[upvote_answer upvote_question accepted_answer answered_question],
    }.freeze
    private_constant :CATEGORIES

    def sum_per_category(scores)
      scores.each_with_object(
        Hash.new {|h, k| h[k] = columns.index_with { 0 } }
      ) do |(key, points), memo|
        course_id, rule = key
        category = lookup_category(rule)

        memo[course_id][category] += points
        memo[course_id][:total] += points
      end
    end

    def sum_total_per_category(result)
      result.merge(
        total: columns.index_with do |category|
          result.values.sum { it[category] }
        end
      )
    end

    def load_courses(result)
      courses = Course::Course.where(id: result.keys, deleted: false).index_by(&:id)

      result.transform_keys do |course_id|
        next I18n.t(:'gamification.scores.total') if course_id == :total

        courses[course_id] || I18n.t(:'gamification.scores.missing_course_title')
      end
    end

    def lookup_category(rule)
      @lookup_category ||= Hash.new do |h, k|
        h[k] = CATEGORIES.find {|_, rules| rules.include?(k) }&.first
      end

      @lookup_category[rule.to_sym]
    end
  end
end
