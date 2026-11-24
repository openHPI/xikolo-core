# frozen_string_literal: true

# A controller that holds actions loosely related to a course
# Should be extracted to proper resource-based controllers
#
class Admin::CourseManagementController < Admin::BaseController
  include CourseContextHelper

  inside_course only: :submissions

  # view for teachers to get a high level overview about submissions
  def submissions
    authorize! 'quiz.submission.index'

    @course = the_course
    Acfs.run # TODO: refactor with callback

    submissions = QuizService::QuizSubmission
      .where(course_id: @course.id)
      .then {|submissions| params[:user_id] ? submissions.where(user_id: params[:user_id]) : submissions }
      .includes(:quiz_submission_questions, :quiz_submission_snapshot, quiz: :item, user: [:primary_email])
      .reorder(quiz_submission_time: :desc)

    # The JSON export should include all matching submissions, not just one page.
    @submissions = request.format.json? ? submissions : submissions.paginate(page: params[:page])

    # TODO: decide how to handle deleted items
    if params[:user_id]
      @user = Xikolo::Account::User.find params[:user_id]
      @homework_submissions = []
      CourseService::Item.where(
        section_id: CourseService::Section.where(course_id: @course.id).select(:id),
        content_type: 'QuizService::Quiz',
        exercise_type: %w[main bonus]
      ).course_order.each do |item|
        @homework_submissions << result = {title: item.title}

        Xikolo::Quiz::Quiz.find item.content.id do |quiz|
          result.merge!(
            quiz_id: quiz.id,
            allowed_attempts: quiz.current_allowed_attempts,
            unlimited_attempts: quiz.current_unlimited_attempts
          )

          if item.section_id
            section = CourseService::Section.find item.section_id
            result[:title] = "#{section.title}/#{result[:title]}"
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
    Acfs.run

    respond_to do |format|
      format.html # renders the default view
      format.json do
        data = @submissions.map {|submission|
          {
            quiz_id: submission.quiz_id,
            submission_id: submission.id,
            user_name: submission.user&.name,
            user_email: submission.user&.primary_email&.address,
            submitted_at: submission.quiz_submission_time,
            grade: submission.points,
          }
        }
        send_data data.to_json, filename: 'submissions.json', type: 'application/json'
      end
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
    redirect_back_or_to(root_path, status: :see_other)
  rescue Restify::ClientError
    raise Status::NotFound
  end

  def import_quizzes
    authorize! 'course.content.edit'
    the_course
    Acfs.run

    begin
      QuizImporter.import(
        spreadsheet: params[:spreadsheet],
        worksheet: params[:worksheet],
        course_code: the_course.course_code
      )
    rescue QuizImporter::LoadWorksheetError, QuizImporter::ProcessWorksheetError => e
      add_flash_message :error, e.message
      redirect_to course_sections_path(params[:id]), status: :see_other
      return
    end

    add_flash_message :success, t(:'items.quiz.import_quizzes_success')
    redirect_to course_sections_path(params[:id]), status: :see_other
  end

  def generate_ranking
    authorize! 'course.ranking.persist'
    Xikolo.api(:course).value!.rel(:course_persist_ranking_task).post({}, params: {course_id: the_course.id}).value!
    add_flash_message :success, t(:'admin.courses.generate_ranking.success.title')
    redirect_to edit_course_path(params[:id]), status: :see_other
  end

  private

  def auth_context
    the_course.context_id
  end

  # fix course receiving
  def request_course
    course = CourseService::Course.by_identifier(params[:id]).take
    if course.nil?
      raise Status::NotFound
    end

    course
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
# rubocop:enable all
