# frozen_string_literal: true

require 'addressable'

class QuizItemPresenter < ItemPresenter
  include Rails.application.routes.url_helpers
  include UUIDHelper

  # TODO: remove it -> generate urls without section
  def_delegators :@quiz, :current_unlimited_attempts, :max_points,
    :current_allowed_attempts, :current_time_limit_seconds,
    :current_unlimited_time
  def_delegator :@attempts, :attempts

  attr_reader :course, :submission, :error

  def self.build(item, course, user, quiz = nil, **)
    if quiz.nil?
      quiz = Xikolo::Quiz::Quiz.find UUID(item['content_id']), &:enqueue_acfs_request_for_questions
    end
    Acfs.run
    Acfs.run

    presenter = new(item:, quiz:, course:, user:)
    presenter.enrollment!
    presenter.submission!
    presenter
  end

  def enrollment!
    @enrollment = Xikolo::Course::Enrollment.find_by(course_id: @course.id, user_id: @user.id)
  end

  def submission!
    Acfs.on @quiz, @enrollment do |quiz, enrollment|
      if enrollment.nil?
        @error = I18n.t(:'items.show.quiz.error_not_enrolled')
        next
      end

      Xikolo::Submission::QuizSubmission.where(
        quiz_id: quiz.id,
        user_id: @user.id,
        newest_first: true
      ) do |submissions|
        @submission = submissions.first
        @attempts = Xikolo::Submission::UserQuizAttempts.find(
          user_id: @user.id,
          quiz_id: quiz.id
        ) do |attempts|
          # TODO: - move to correct possition -> feed back to controller

          # Do not redirect if deadline has passsed and no prior submission
          # exists
          if !submission_deadline_passed? || @submission.present?
            if skip_quiz_instructions? && required_item_ids.empty?
              if !quiz_taken? && (attempts.attempts_for_quiz_remaining?(quiz) || quiz.current_unlimited_attempts)
                @redirect = new_course_item_quiz_submission_path @course.course_code, short_uuid(id)
              else
                @redirect = course_item_quiz_submission_path(
                  @course.course_code,
                  short_uuid(id),
                  short_uuid(@submission.id)
                )
              end
            elsif quiz_taken? && (!@submission.submitted || user_instrumented_or_access_allowed?)
              @redirect = course_item_quiz_submission_path(
                @course.course_code,
                short_uuid(id),
                short_uuid(@submission.id)
              )
            elsif quiz_taken? && (no_further_submission_possible? || user_instrumented_or_access_allowed?)
              @redirect = course_item_quiz_submission_path(
                @course.course_code,
                short_uuid(id),
                short_uuid(@submission.id),
                highest_score: highest_score?
              )
            end
          end
        end
      end
    end
  end

  def question_count
    if @quiz.questions.nil?
      '-' # Unknown amount of questions... necessary only in dev env?
    else
      @quiz.questions.count
    end
  end

  def partial_name
    if submission_deadline_passed? && !user_instrumented?
      'items/quiz/quiz_submission_deadline_passed'
    else
      super
    end
  end

  def show_info_ungraded?
    return false if graded?

    @quiz.current_unlimited_attempts || survey?
  end

  def instructions
    @quiz.instructions
  end

  def survey?
    exercise_type.blank? || exercise_type == 'survey'
  end

  def graded?
    exam? || bonus?
  end

  def basic_quiz_properties
    props = []

    if main_exercise?
      props << {name: 'homework', icon_class: 'money-check-pen'}
    elsif bonus_exercise?
      props << {name: 'bonus', icon_class: 'lightbulb-on+circle-star'}
    elsif selftest?
      props << {name: 'selftest', icon_class: 'lightbulb-on'}
    end

    if current_unlimited_time
      props << {name: 'unlimited_time', icon_class: 'timer'}
    elsif current_time_limit_seconds
      props << {
        name: 'time_limit',
        icon_class: 'timer',
        opts: {limit: current_time_limit_seconds / 60},
      }
    end

    if current_unlimited_attempts
      props << {name: 'unlimited_attempts', icon_class: 'ban'}
    elsif current_allowed_attempts > 0
      props << {
        name: 'allowed_attempts',
        icon_class: 'ban',
        opts: {count: current_allowed_attempts},
      }
    end

    props
  end

  # Only called on quiz intro page
  def proctored_quiz_unavailable?
    @user.feature?('proctoring') &&
      proctoring_context.enabled? &&
      !proctoring_service_available? &&
      !user_instrumented?
  end

  def highest_score?
    # For proctored exams, we always use the newest attempt and not the highest
    # score. For regularly graded exams, it is the other way around.
    !(@user.feature?('proctoring') && proctoring_context.enabled?)
  end

  # Only called when viewing the submission
  def quiz_submittable?
    # Do not allow to submit a quiz if proctoring is enabled but the service is
    # unavailable.
    !@user.feature?('proctoring') ||
      (@user.feature?('proctoring') && !proctoring_context.enabled?) ||
      (@user.feature?('proctoring') && proctoring_context.enabled? && proctoring_service_available?) ||
      user_instrumented?
  end

  def attempts_left?
    @attempts.attempts_for_quiz_remaining?(@quiz) || @quiz.current_unlimited_attempts
  end

  def quiz_taken?
    !@submission.nil?
  end

  def show_quiz_results?
    quiz_results_published? ||
      submission_deadline.nil? ||
      submission_publishing_date.nil? ||
      user_instrumented_or_access_allowed?
  end

  def preview_quiz_score?
    @user.feature? 'preview_graded_quiz_points'
  end

  def preview_score_html
    locals = {
      quiz_submission_time: I18n.l(
        @submission.quiz_submission_time.in_time_zone,
        format: :long
      ),
      timezone: Time.zone.name,
      points: @submission.points.round(1),
      max_points: @quiz.max_points.round(1),
      percent: (@submission.points / @quiz.max_points * 100).round(1),
    }

    ApplicationController.render partial: 'items/quiz/score_preview', locals:
  end

  def allow_retake_quiz?
    attempts_left? && (!submission_deadline_passed? || user_instrumented?)
  end

  def allow_retake_or_view_results?
    attempts_left? &&
      (submission_deadline.nil? ||
        (Time.zone.now < submission_deadline &&
          (submission_publishing_date.nil? ||
             Time.zone.now > submission_publishing_date
          )
        )
      )
  end

  def confirm_quiz_start?
    graded?
  end

  def submission_deadline_passed?
    submission_deadline.present? && submission_deadline < Time.zone.now
  end

  private

  def exam?
    exercise_type == 'main'
  end

  def bonus?
    exercise_type == 'bonus'
  end

  def no_further_submission_possible?
    submission_deadline_passed? || !attempts_left?
  end

  def skip_quiz_instructions?
    %w[selftest survey].include?(exercise_type)
  end

  def quiz_results_published?
    submission_publishing_date.present? &&
      (Time.zone.now > submission_publishing_date)
  end

  def user_instrumented?
    @user.instrumented?
  end

  def user_instrumented_or_access_allowed?
    user_instrumented? || @user.allowed?('course.content.access')
  end

  # Temporary: Proctoring is not offered anymore.
  def proctoring_service_available?
    false
  end

  def proctoring_context
    @proctoring_context ||= Proctoring::ItemContext.new @course, @item, @enrollment
  end

  def course_proctoring
    @course_proctoring ||= Proctoring::SmowlAdapter.new(nil)
  end

  def enrollment_proctoring
    @enrollment_proctoring ||= Course::Enrollment.find(@enrollment.id).proctoring
  end
end
