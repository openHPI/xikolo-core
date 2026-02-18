# frozen_string_literal: true

class QuizSubmissionController < Abstract::FrontendController
  include CourseContextHelper
  include ItemContextHelper

  before_action :ensure_logged_in
  before_action :set_no_cache_headers

  inside_course
  inside_item

  respond_to :json

  def request_section
    course_api.rel(:section).get({id: UUID(item['section_id'])})
  end

  def show
    the_quiz
    Acfs.run # Load shared promises

    raise TypeError unless item['content_type'] == 'quiz'
    raise Status::NotFound if (uuid = UUID4.try_convert(params[:id])).nil?

    # Retrieve the submission from the url
    submission_from_url = Xikolo.api(:quiz).value!.rel(:quiz_submission).get({id: uuid.to_s}).value!
    # Access submission only if owner or course admin
    unless submission_from_url['user_id'] == current_user.id || current_user.allowed?('quiz.submission.manage')
      add_flash_message :error, t(:'flash.error.not_authorized')
      return redirect_to root_url, status: :see_other
    end

    create_visit!

    # This query returns a limited list of 50 results
    @submissions = Xikolo::Submission::QuizSubmission.where(
      quiz_id: the_quiz.id, user_id: current_user.id, highest_score: highest_score?, newest_first: newest_first?
    ) do |submissions|
      sid = if highest_score?
              submissions.first.id
            else
              submission_from_url['id']
            end
      @submission = Xikolo::Submission::QuizSubmission.find sid do |submission|
        submission.enqueue_acfs_request_for_quiz_submissions_questions do |submission_questions|
          submission_questions.each(&:enqueue_acfs_request_for_quiz_submissions_answers)
        end
        @quiz = Xikolo::Quiz::Quiz.find item['content_id'] do |quiz|
          quiz.enqueue_acfs_request_for_questions do |questions|
            questions.each(&:enqueue_acfs_request_for_answers)
          end
          @attempts = Xikolo::Submission::UserQuizAttempts.find user_id: current_user.id, quiz_id: quiz.id
        end
      end
    end

    Acfs.run
    @submissions.select!(&:submitted)

    Acfs.run

    unless @submission.submitted
      redirect_to new_course_item_quiz_submission_path(item_id: params[:item_id]), status: :see_other
      return
    end

    @my_result = QuizResultPresenter.new(@quiz, @submission, @submissions)

    submission = Quiz::Submission.from_acfs(@submission)
    if submission.proctored?
      @quiz_proctoring = QuizSubmissionProctoringPresenter.new(submission.proctoring)
    end

    shuffle_answers @quiz, @submission.id.to_i

    set_page_title the_course.title, item['title']
  end

  def new
    @quiz = the_quiz

    # Load course, quiz and other main resources
    Acfs.run

    raise TypeError unless item['content_type'] == 'quiz'
    raise TypeError unless the_quiz && (item['content_id'] == the_quiz.id)

    if item['submission_deadline'].present? && item['submission_deadline'] < ::Time.zone.now
      add_flash_message :error, t(:'flash.error.quiz_submissions_submission_deadline_passed')
      return redirect_to course_item_path(id: short_uuid(item['id'])), status: :see_other
    end

    # Temporary: We do not offer proctoring anymore, so do no allow starting
    # the quiz.
    if proctoring?
      add_flash_message :error, t(:'flash.error.quiz_submission_proctoring_unavailable')
      return redirect_to course_item_path(id: short_uuid(item['id'])), status: :see_other
    end

    nowts = DateTime.now.in_time_zone.to_i

    begin
      submission = quiz_api.rel(:quiz_submissions).post({
        course_id: the_course.id,
        quiz_id: @quiz.id,
        user_id: current_user.id,
        vendor_data: proctoring? ? {proctoring: 'smowl_v2'} : nil,
      }).value!

      # To prevent breakage in other parts, let's wrap the Restify response in
      # an Acfs client object for now.
      # TODO: Use the Restify response wrapped in a presenter everywhere
      @submission = Xikolo::Submission::QuizSubmission.new submission.to_h
      @submission.loaded!
    rescue Restify::UnprocessableEntity
      add_flash_message :error, t(:'flash.error.quiz_submissions_maximum_reached')
      return redirect_to course_item_path(id: short_uuid(item['id'])), status: :see_other
    end

    if @submission['snapshot_id']
      @submission_snapshot = Xikolo::Submission::QuizSubmissionSnapshot.find(@submission['snapshot_id'])
      Acfs.run
    end

    # Test if timer for the un-submitted quiz is still running,
    unless submission_in_time?(@quiz, @submission, nowts)
      submission_data = nil
      unless @submission_snapshot.nil? || @submission_snapshot.loaded_data.nil?
        submission_data = @submission_snapshot.loaded_data
      end
      begin
        # Can fail because there is already some data
        @submission.update_attributes({submitted: true, submission: submission_data})
      rescue
        @submission.update_attributes({submitted: true, submission: nil})
      end
      add_flash_message :error, t(:'flash.error.quiz_submission_time_up')
      return redirect_to course_item_quiz_submission_path(id: short_uuid(@submission.id)), status: :see_other
    end

    create_visit!

    if submission.response.status != :created && @item_presenter.graded? && !@in_app
      add_flash_message :notice, t(:'flash.notice.quiz_submission_still_active')
    end

    # Adjust counter_end_time if deadline would exceed current_time_limit and current_user is not masqueraded
    if item['submission_deadline'] &&
       !current_user.instrumented? &&
       !current_user.allowed?('course.content.access')
      submission_deadline = Time.parse(item['submission_deadline'].to_s).to_i
    else
      submission_deadline = nil
    end

    quiz_access_time = @submission.quiz_access_time
    quiz_end_time = quiz_access_time ? quiz_access_time.to_i + @quiz.current_time_limit_seconds : nil

    @counter_end_timediff = [
      submission_deadline,
      quiz_end_time,
    ].compact.min - nowts
    @counter_init_timestamp = nowts
    shuffle_answers @quiz, @submission.id.to_i

    set_page_title the_course.title, item['title']
  end

  def create
    if params[:quiz_id]
      quiz = Xikolo::Quiz::Quiz.find(params[:quiz_id]) do |resource|
        @attempts = Xikolo::Submission::UserQuizAttempts.find(user_id: current_user.id, quiz_id: resource.id)
      end
    else
      quiz = nil
    end
    submission = if params[:quiz_submission_id].present?
                   Xikolo::Submission::QuizSubmission.find UUID(params[:quiz_submission_id])
                 end
    Acfs.run

    # Show an error message if no corresponding quiz is found.
    # This should never happen as it would mean the content resource for this
    # item has been deleted.
    if quiz.nil?
      add_flash_message :error, t(:'flash.error.quiz_submission_failed')
      return redirect_to course_item_path(id: short_uuid(params[:item_id])), status: :see_other
    end

    # Test if the time for submission is up, including a buffer of 1 minute, e.g.
    # for js auto-submit. Masked users can always create a submission.
    if !submission_in_time?(quiz, submission, 60.seconds.ago.in_time_zone.to_i) && !current_user.instrumented?
      submit! submission unless submission.submitted
      add_flash_message :error, t(:'flash.error.quiz_submission_time_up')
      return redirect_depending_on_quiz_type quiz, submission
    end

    # Show an error message that no answers were submitted when the submission
    # data is missing, i.e. no answers were selected.
    unless params[:submission]
      submit! submission
      add_flash_message :error, t(:'flash.error.quiz_submission_no_answers')
      return redirect_depending_on_quiz_type quiz, submission
    end

    begin
      # This can fail in case there is already some submission data.
      submit! submission, params[:submission]
    rescue
      submit! submission
    end

    # Throwing the event here as the `item_id` needs to be provided, which
    # is not available in the quiz service.
    submissions = Xikolo::Submission::QuizSubmission.where(
      quiz_id: submission.quiz_id, user_id: submission.user_id, per_page: 1
    )
    created_submission = Xikolo::Submission::QuizSubmission.find(submission.id)

    Acfs.run

    Msgr.publish({
      id: created_submission.id,
      course_id: created_submission.course_id,
      item_id: @item_presenter.id,
      quiz_id: created_submission.quiz_id,
      quiz_access_time: created_submission.quiz_access_time,
      quiz_submission_time: created_submission.quiz_submission_time,
      quiz_version_at: created_submission.quiz_version_at,
      quiz_submission_deadline: @item_presenter.submission_deadline,
      quiz_type: @item_presenter.exercise_type,
      user_id: created_submission.user_id,
      submitted: created_submission.submitted,
      points: created_submission.points,
      attempt: submissions.total_pages,
      max_points: quiz.present? ? quiz.max_points : nil,
      estimated_time_effort: @item_presenter.time_effort,
    }, to: 'xikolo.submission.submission.create')

    add_flash_message :success, t(:'flash.success.quiz_submitted')
    redirect_depending_on_quiz_type quiz, submission
  rescue Acfs::ErroneousResponse
    add_flash_message :error, t(:'flash.error.quiz_submission_failed')
    redirect_to course_item_path(id: short_uuid(params[:item_id])), status: :see_other
  end
  private

  def request_item
    return nil unless params[:item_id]

    get_params = {id: UUID4(params[:item_id]).to_s}.tap do |p|
      # Authorized users (e.g., course admins) can always access items, but
      # for regular learners the user-specific access is verified.
      p[:user_id] = current_user.id unless current_user.allowed? 'course.content.access'
      p[:for_user] = current_user.id if current_user.feature? 'course.reactivated'
    end

    course_api.rel(:item).get(get_params)
  end

  def auth_context
    the_course.context_id
  end

  def create_item_presenter!
    Acfs.on the_course, the_quiz do |course, quiz|
      presenter_class = ItemPresenter.lookup(item)
      @item_presenter = presenter_class.build item, course, current_user, quiz
    end
  end

  def highest_score?
    # For regularly graded (not proctored) exams, we use the highest score not the newest attempt.
    !proctoring? && (params[:highest_score] == 'true')
  end

  def newest_first?
    # For proctored exams, we always use the newest attempt and not the highest score.
    # Can be enforced by setting the newest_first param.
    proctoring? || (params[:newest_first] == 'true')
  end

  def shuffle_answers(quiz, randomkey)
    quiz.questions.select(&:shuffle_answers).each do |question|
      # Random key must be unique per question, so we add the question id
      question.answers.shuffle! random: Random.new(randomkey + question.id.to_i)
    end
  end

  def submission_in_time?(quiz, submission, timestamp)
    return true if quiz.current_unlimited_time

    # Convert DateTime into seconds since epoch with `.to_i`
    submission.quiz_access_time.in_time_zone.to_i + quiz.current_time_limit_seconds > timestamp
  end

  def attempts_left?
    @quiz.current_unlimited_attempts || @attempts.attempts_for_quiz_remaining?(@quiz)
  end

  def redirect_depending_on_quiz_type(quiz, submission)
    if skip_quiz_instructions?
      redirect_to course_item_quiz_submission_path(id: short_uuid(submission.id)), status: :see_other
    elsif quiz.current_unlimited_attempts || further_quiz_attempt?(quiz)
      redirect_to course_item_path(id: short_uuid(params[:item_id])), status: :see_other
    else
      redirect_to course_item_quiz_submission_path(id: short_uuid(submission.id), highest_score: false),
        status: :see_other
    end
  end

  def further_quiz_attempt?(quiz)
    @attempts.remaining_attempts_for_quiz(quiz) - 1 > 0
  end

  def enrollment
    return @enrollment if defined? @enrollment

    @enrollment = Course::Enrollment.active.find_by!(course_id: the_course.id, user_id: current_user.id)
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def the_quiz
    promises[:quiz] ||= begin
      promise, fulfiller = create_promise(Xikolo::Quiz::Quiz.new)
      Xikolo::Quiz::Quiz.find UUID(item['content_id']) do |quiz|
        quiz.enqueue_acfs_request_for_questions do |questions|
          questions.each(&:enqueue_acfs_request_for_answers)
        end
        fulfiller.fulfill quiz
      end

      promise
    end
  end

  def submit!(submission, submission_data = nil)
    submission.update_attributes({submission: submission_data, submitted: true})
  end

  def proctoring?
    current_user.feature?('proctoring') && proctoring_context.enabled?
  end

  def proctoring_context
    @proctoring_context ||= Proctoring::ItemContext.new(the_course, item, enrollment)
  end

  def skip_quiz_instructions?
    %w[selftest survey].include?(item['exercise_type'])
  end
end
