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
    @enrollment = CourseService::Enrollment.find_by(course_id: @course.id, user_id: @user.id)
  end

  def submission!
    Acfs.on @quiz do |quiz|
      if @enrollment.nil?
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
              if !quiz_taken?
                && (attempts.attempts_for_quiz_remaining?(quiz) || quiz.current_unlimited_attempts) && !exam_locked?
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
    if @quiz.question_pool
      @quiz.displayed_question_count
    elsif @quiz.questions.nil?
      '-' # Unknown amount of questions... necessary only in dev env?
    else
      @quiz.questions.count
    end
  end

  # Whether the quiz has a finite time limit and thus a remaining-time
  # indicator to show.
  def time_limited?
    !current_unlimited_time && current_time_limit_seconds.present?
  end

  # Number of attempts the learner may still make, or `nil` when unlimited.
  # Falls back to the configured allowed attempts when no attempts record
  # exists yet (e.g. first time taking the quiz).
  def attempts_left
    return nil if current_unlimited_attempts

    if @attempts
      @attempts.remaining_attempts_for_quiz(@quiz)
    else
      current_allowed_attempts
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
    main_exercise? || bonus? || exam?
  end

  def basic_quiz_properties
    props = []

    if main_exercise?
      props << {name: 'homework', icon_class: 'money-check-pen'}
    elsif bonus_exercise?
      props << {name: 'bonus', icon_class: 'lightbulb-on+circle-star'}
    elsif selftest?
      props << {name: 'selftest', icon_class: 'lightbulb-on'}
    elsif exam?
      props << {name: 'exam', icon_class: 'certificate'}
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

  def highest_score?
    true
  end

  def quiz_submittable?
    true
  end

  def attempts_left?
    return false if exam_passed?

    @attempts.attempts_for_quiz_remaining?(@quiz) || @quiz.current_unlimited_attempts
  end

  def pass_percentage
    @quiz['pass_percentage'] || 70
  end

  # The maximum points a learner can earn in a single attempt. For question-pool
  # exams this is the total of the displayed question set, not the whole pool.
  def displayed_max_points
    return max_points unless @quiz.question_pool

    batches = (@quiz.displayed_question_count.to_i / QuizService::Quiz::EXAM_QUESTIONS_PER_BATCH).to_i
    batches * QuizService::Quiz::EXAM_QUESTION_DIFFICULTIES
      .sum {|_difficulty, cfg| cfg[:points] * cfg[:count] }
  end

  # Did the learner pass the exam with their latest submitted attempt?
  def exam_passed?
    return false unless exam?
    return false if @submission.nil? || !@submission['submitted']

    points = @submission['points'].to_f
    max = @submission['max_points'].to_f
    return false if max.zero?

    points * 100 / max >= pass_percentage
  end

  def exam_locked_for?(user_id)
    return false unless exam?
    return false if user_id.blank?

    progress = CourseService::CourseProgress.find_by(course_id:, user_id:)
    return true if progress.nil?

    progress.visits_percentage < (minimum_progress_percentage || 75)
  end

  def instruction_action
    return :locked if exam_locked_for?(@user.id)

    unless quiz_taken?
      return exam? && confirm_quiz_start? ? :start_exam : :start_quiz
    end

    return :retake_with_results if allow_retake_or_view_results?
    return :retake if attempts_left? && !submission_deadline.nil?

    nil
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
end
