# frozen_string_literal: true

module CourseService
class AchievementsDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_api_v1(_opts = {})
    [confirmation_of_participation, record_of_achievement]
  end

  private

  def points
    if model.enrollment.present?
      {
        achieved: format_points(model.enrollment.user_dpoints),
        total: format_points(model.enrollment.maximal_dpoints),
        percentage: model.user_completion_percentage.to_i,
      }
    else
      {achieved: 0.0, total: 0.0, percentage: 0}
    end
  end

  def visits
    {
      achieved: model.enrollment&.visits_visited.to_i,
      total: model.enrollment&.visits_total.to_i,
      percentage: model.user_visit_percentage.to_i,
    }
  end

  def confirmation_of_participation
    {
      type: 'confirmation_of_participation',
      name: I18n.t(:'course_service.achievements.certificates.confirmation.name'),
      achieved: model.cop.achieved?,
      achievable: model.cop.achievable?,
      description: I18n.t(:"course_service.achievements.certificates.confirmation.state.#{model.cop_state}"),
      requirements: confirmation_requirements,
      download: confirmation_download.presence || progress(model.cop).presence,
      visits:,
    }
  end

  def record_of_achievement
    {
      type: 'record_of_achievement',
      name: I18n.t(:'course_service.achievements.certificates.achievement.name'),
      achieved: model.roa.achieved?,
      achievable: model.roa.achievable?,
      description: I18n.t(:"course_service.achievements.certificates.achievement.state.#{model.roa_state}"),
      requirements: achievement_requirements,
      download: achievement_download.presence || progress(model.roa).presence,
      points:,
    }
  end

  def confirmation_requirements
    return [] unless model.cop.enabled?

    [
      {
        type: 'progress',
        achieved: model.cop.achieved?,
        description: I18n.t(
          :'course_service.achievements.certificates.confirmation.requirements.progress',
          course_percentage: model.course.cop_threshold_percentage.to_i
        ),
      },
    ]
  end

  def achievement_requirements
    return [] unless model.roa.enabled?

    [
      {
        type: 'completion',
        achieved: model.roa.achieved?,
        description: I18n.t(
          :'course_service.achievements.certificates.achievement.requirements.completion',
          course_percentage: model.course.roa_threshold_percentage.to_i
        ),
      },
    ]
  end

  def confirmation_download
    return unless model.cop.achieved?

    if model.cop.released?
      {
        available: true,
        description: nil,
        url: Xikolo.base_url.join('certificate/render?' \
                                  "course_id=#{model.course.id}&type=ConfirmationOfParticipation"),
        type: 'download',
      }
    else
      {
        available: false,
        description: I18n.t(:'course_service.achievements.certificates.confirmation.download.not_released'),
        url: nil,
        type: 'download',
      }
    end
  end

  def achievement_download
    return unless model.roa.achieved?

    if model.roa.released?
      {
        available: true,
        description: nil,
        url: Xikolo.base_url.join('certificate/render?' \
                                  "course_id=#{model.course.id}&type=RecordOfAchievement"),
        type: 'download',
      }
    else
      {
        available: false,
        description: I18n.t(:'course_service.achievements.certificates.achievement.download.not_released'),
        url: nil,
        type: 'download',
      }
    end
  end

  def progress(achievement)
    return unless achievement.achievable?

    {
      url: Xikolo.base_url.join("courses/#{model.course.course_code}/progress"),
      type: 'progress',
    }
  end

  def format_points(value)
    (value / 10.0).to_f
  end
end
end
