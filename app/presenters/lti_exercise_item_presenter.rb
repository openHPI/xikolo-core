# frozen_string_literal: true

class LtiExerciseItemPresenter < ItemPresenter
  include MarkdownHelper

  def self.build(item, course, user, params:)
    new(course:, item:, user:, initial_click: !params[:lti])
  end

  def lti_grades
    @lti_grades ||= if exercise_type == 'survey' || exercise.nil?
                      nil
                    else
                      exercise.gradebooks.where(user_id: @user.id).first&.grades&.order(value: :desc)
                    end
  end

  def score
    @score ||= lti_grades.present? ? (lti_grades.first.score * max_points).round(2) : nil
  end

  def percentage
    @percentage ||= lti_grades.present? ? (lti_grades.first.score * 100).floor : nil
  end

  def error
    I18n.t(:'items.lti.not_available') unless provider
  end

  def instructions_html
    render_markdown exercise.instructions&.external
  end

  def instructions?
    exercise.instructions.present?
  end

  ##
  # Decide whether to show an intro page or an embedded launch iframe.
  #
  def partial_name
    if submission_deadline_passed? && !@user.instrumented?
      'items/quiz/quiz_submission_deadline_passed'
    elsif needs_intro?
      super
    else
      'items/lti_exercise/launch_iframe'
    end
  end

  def needs_intro?
    # We need an intro page for external exercises (in order to display a
    # "Launch" button) and for exercises that can have points (in order to
    # show the results).
    #
    # @initial_click is set to false when clicking on the launch button
    external? || (!exercise_without_points? && @initial_click)
  end

  def exercise_without_points?
    exercise_type == ''
  end

  def grades?
    lti_grades.present?
  end

  def presentation_as_window?
    provider.presentation_mode == 'window'
  end

  def tool_launch_path
    Rails.application.routes.url_helpers
      .tool_launch_course_item_path(@course.course_code, to_param)
  end

  ##
  # Where should the launch button lead us?
  #
  # Most exercises will go directly to the launch page, which makes a signed
  # request to the LTI tool.
  # For exercises that should be opened in an iframe, we link to a special page
  # that embeds the tool in an iframe.
  #
  def open_path
    if iframe?
      Rails.application.routes.url_helpers
        .course_item_lti_path(@course.course_code, to_param)
    else
      tool_launch_path
    end
  end

  def submission_deadline_passed?
    submission_deadline.present? && submission_deadline < Time.zone.now
  end

  private

  def exercise
    @exercise ||= Lti::Exercise.find(content_id)
  end

  def provider
    @provider ||= exercise.provider
  end

  def iframe?
    provider.presentation_mode == 'frame'
  end

  def external?
    !iframe?
  end
end
