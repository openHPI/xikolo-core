# frozen_string_literal: true

# A controller that holds actions loosely related to a course
# Should be extracted to proper resource-based controllers
#
class Admin::CourseManagementController < Admin::BaseController
  include CourseContextHelper

  before_action :set_no_cache_headers

  inside_course only: %i[submissions statistic submission_statistics]

  respond_to :json

  def statistic
    authorize! 'course.statistics.show'
    @stats = Xikolo::Course::Stat.find(course_id: the_course.id, key: 'enrollments_by_day')
    Acfs.run
    render json: @stats.student_enrollments_by_day
  end

  # view for teachers to get a high level overview about submissions
  def submissions
    authorize! 'quiz.submission.index'
    reqparam = {}
    reqparam[:page] = if params[:page].nil?
                        1 # !TODO: Do this global for all paging support controllers?
                      else
                        params[:page]
                      end
    load_course
    Acfs.run # TODO: refactor with callback
    reqparam[:course_id] = @course.id
    reqparam[:user_id] = params[:user_id] if params[:user_id]
    reqparam[:newest_first] = 'true'
    @submission_users = {}
    @submissions = quiz_api.rel(:quiz_submissions).get(reqparam).value!

    @submissions.each do |submission|
      @submission_users[submission['user_id']] ||= Xikolo::Account::User.find(submission['user_id'])
      quiz_submission = Quiz::Submission.from_restify(submission)
      submission['proctoring'] = quiz_submission.proctoring if quiz_submission.proctored?
    end

    # TODO: decide how to handle deleted items
    if params[:user_id]
      @user = Xikolo::Account::User.find params[:user_id]
      @homework_submissions = []
      Xikolo::Course::Item.where course_id: @course.id, content_type: 'quiz', exercise_type: %w[main bonus] do |items|
        items.each do |item|
          @homework_submissions << result = {
            title: item.nil? ? 'Deleted item' : item.title,
          }

          Xikolo::Quiz::Quiz.find item.content_id do |quiz|
            result.merge!(
              quiz_id: quiz.id,
              allowed_attempts: quiz.current_allowed_attempts,
              unlimited_attempts: quiz.current_unlimited_attempts
            )

            if item.section_id
              Xikolo::Course::Section.find item.section_id do |section|
                result[:title] = "#{section.title}/#{result[:title]}"
              end
            end

            quiz_api.rel(:user_quiz_attempts).get({
              user_id: params[:user_id],
              quiz_id: quiz.id,
            }).then do |attempts|
              remaining_attempts = quiz.current_allowed_attempts +
                                   attempts['additional_attempts'] -
                                   attempts['attempts']

              result.merge!(
                additional_attempts: attempts['additional_attempts'],
                remaining_attempts:,
                attempts: attempts['attempts']
              )
            end.value
          end
        rescue Acfs::InvalidResource
        end
      end
    end
    Acfs.run

    @submissions.each do |submission|
      submission['quiz_title'] = Course::Item.find_by(content_id: submission['quiz_id'])&.title
    end
  end

  def convert_submission
    authorize! 'quiz.submission.manage'
    if params[:submission_id] && params[:snapshot_id]
      submission = quiz_api.rel(:quiz_submission).get({id: params[:submission_id]}).value!
      snapshot = quiz_api.rel(:quiz_submission_snapshot).get({id: params[:snapshot_id]}).value!

      if snapshot['loaded_data']
        submission.rel(:self).patch({
          submission: snapshot['loaded_data'],
          submitted: true,
        }).value!
      end

      add_flash_message :success, t(:'flash.success.submission_converted')
    end
    redirect_back fallback_location: root_path
  rescue Restify::ClientError
    raise Status::NotFound
  end

  def preview_quizzes
    authorize! 'course.content.edit'
    the_course
    Acfs.run

    data = {
      course_code: the_course.course_code,
      course_id: the_course.id,
      xml: File.read(params[:xml].path).force_encoding('utf-8'),
    }
    begin
      resource = Xikolo.api(:quiz).value!.rel(:quizzes)
        .post(data, params: {preview: true}).value!
      render json: resource.data
    rescue Restify::ClientError => e
      render json: {error: e.errors}, status: e.status
    end
  end

  def import_quizzes
    authorize! 'course.content.edit'
    the_course
    Acfs.run
    Xikolo::Quiz::Quiz.create!(
      course_code: the_course.course_code,
      course_id: the_course.id,
      xml: params[:xml].force_encoding('utf-8')
    )
    render json: {success: 'Ok'}
  rescue Acfs::ErroneousResponse => e
    render json: {error: e.errors}, status: :unprocessable_entity
  end

  def import_quizzes_by_service
    authorize! 'course.content.edit'
    the_course
    Acfs.run

    begin
      resource = Restify.new(Xikolo::Common::API.services[:quizimporter]).get({
        spreadsheet: params[:spreadsheet],
        worksheet: params[:worksheet],
        course_code: the_course.course_code,
      }).value!
    rescue Restify::ClientError, Restify::ServerError => e
      add_flash_message :error, e.response.body.force_encoding('utf-8')
      redirect_to course_sections_path params[:id]
      return
    end

    Xikolo::Quiz::Quiz.create(
      course_code: the_course.course_code,
      course_id: the_course.id,
      xml: resource.data.force_encoding('utf-8')
    )
    add_flash_message :success, t(:'items.quiz.import_quizzes_success')
    redirect_to course_sections_path params[:id]
  end

  def generate_ranking
    authorize! 'course.ranking.persist'
    Xikolo.api(:course).value!.rel(:course_persist_ranking_task).post({}, params: {course_id: the_course.id}).value!
    head :ok
  end

  # this is totally ruff, but is a blueprint for our analytics master thesis (jr)
  def submission_statistics
    authorize! 'quiz.statistics.show'

    @course = the_course
    @stats_quizzes = {}
    @stats = {}
    @stats_titles = {}
    @items = []
    @sections = Xikolo.api(:course).value!.rel(:sections).get({
      course_id: the_course.id,
      include_alternatives: true,
    }).value!.index_by {|s| s['id'] }

    Xikolo::Course::Item.each_item(course_id: the_course.id, content_type: 'quiz', was_available: true) do |quiz_item|
      @items << quiz_item
      next if quiz_item.id != params[:stat_id]

      Xikolo::Quiz::Quiz.find quiz_item.content_id do |quiz|
        stat = quiz_api.rel(:submission_statistic).get({
          id: quiz.id,
          embed: 'avg_submit_duration,submissions_over_time,questions',
        }).value!
        next if stat.blank?

        @stats[quiz.id] = stat
        @stats_quizzes[quiz.id] = quiz
        @stats_titles[quiz.id] = quiz_item.title

        quiz.enqueue_acfs_request_for_questions do |questions|
          questions.each(&:enqueue_acfs_request_for_answers)
        end
      end
    end
    Acfs.run
    @items.sort_by! {|i| [@sections[i.section_id]['position'], i.position] }
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def load_course
    @course = Xikolo::Course::Course.find(params[:id]) do |course|
      @sections = course.sections do |sections|
        sections.each(&:items)
      end
      enrollments = []
      if current_user.logged_in?
        Xikolo::Course::Enrollment.each_item(user_id: current_user.id) do |enrollment|
          enrollments << enrollment
        end
      end
      @course_presenter = CoursePresenter.create(course, current_user, enrollments)
    end
  end

  # fix course receiving
  def request_course
    Xikolo::Course::Course.find(params[:id])
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
# rubocop:enable all
