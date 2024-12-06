# frozen_string_literal: true

class Achievements
  include Draper::Decoratable

  attr_accessor :course
  attr_reader :enrollment

  def initialize(course_id, user_id)
    @course = Course.find(course_id)
    @enrollment = if user_id.present?
                    LearningEvaluation.by_params({learning_evaluation: 'true'}).call(
                      Enrollment.where(course_id:, user_id:)
                    ).first
                  end
  end

  def roa
    @roa ||= Achievements::RecordOfAchievement.new @course, @enrollment
  end

  def cop
    @cop ||= Achievements::ConfirmationOfParticipation.new @course, @enrollment
  end

  def cop_state
    return :unavailable unless cop.enabled?
    return :not_achieved if !cop.achieved? && !roa.achieved?

    if cop.achieved?
      cop.released? ? :released : :not_released
    elsif cop.achieved_via_roa?
      roa.released? ? :achieved_via_roa : :not_achieved_via_roa
    end
  end

  def user_visit_percentage
    @enrollment.present? ? @enrollment.visits_percentage : 0
  end

  def cop_percentage_difference
    (course.cop_threshold_percentage.to_f - user_visit_percentage.to_f).to_i
  end

  def roa_state
    return :unavailable unless roa.enabled?

    if roa.achieved?
      roa.released? ? :released : :not_released
    else
      return :no_longer_achievable if @enrollment.present? && !roa.achievable?
      return :reactivatable if course.allows_reactivation?

      :not_achieved
    end
  end

  def user_completion_percentage
    return 0 if @enrollment.blank? || @enrollment.maximal_dpoints.zero?

    @enrollment.user_dpoints.to_f / @enrollment.maximal_dpoints * 100
  end

  def roa_points_difference
    return '' if @enrollment.blank? || @enrollment.maximal_dpoints.zero?

    max_dpoints = @enrollment.maximal_dpoints
    user_dpoints = @enrollment.user_dpoints
    target_dpoints = (max_dpoints.to_f / 100) * course.roa_threshold_percentage
    difference_dpoints = [target_dpoints - user_dpoints, 0].max

    I18n.t('achievements.points_difference', count: (difference_dpoints / 10.0).round(1).to_f)
  end
end
