# frozen_string_literal: true

class QuizSubmissionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    submissions = QuizSubmission.all

    # Decorating always access snapshots and e.g. points, which access
    # questions. Therefore, load them at bulk.
    submissions = submissions.includes(:quiz_submission_questions, :quiz_submission_snapshot)

    submissions = submissions.where(id: params[:id]) if params[:id]
    submissions = submissions.where(course_id: params[:course_id]) if params[:course_id]
    submissions = submissions.where(quiz_id: params[:quiz_id]) if params[:quiz_id]
    submissions = submissions.where(quiz_access_time: params[:quiz_access_time]) if params[:quiz_access_time]
    submissions = submissions.where(user_id: params[:user_id]) if params[:user_id]
    submissions = submissions.where_submitted(true) if params[:only_submitted] == 'true'

    if params[:newest_first] == 'true'
      submissions = submissions.reorder('quiz_submission_time DESC')
    end

    # Model loaded from DB
    if params[:highest_score] == 'true'
      submissions = submissions.sort_by_rating
    end

    if params[:submitted]
      submissions = submissions.where_submitted(params[:submitted] == 'true')
    end

    respond_with submissions
  end

  def show
    respond_with QuizSubmission.find(params[:id])
  end

  def create
    submission = quiz.attempt! params.require(:user_id), submission_params.to_h

    if submission.just_created?
      respond_with submission, status: :created
    else
      respond_with submission, status: :ok
    end
  end

  def update
    # Submission example:
    #  {
    #    "user_id": 1,
    #    "quiz_id": 1,
    #    "quiz_access_time": "2013-10-05 16:32:15",
    #    "submission": {
    #      "1": ["1","2"],
    #      "2": "3",
    #      "5": "5"
    #    }
    #  }
    #
    # Explanation:
    #  For multi select questions:
    #    question_id => [ids of selected answers]
    #  For single select questions:
    #    question_id => id of selected answer
    #  For free text questions:
    #    question_id => {id of answer object => answer text}
    #  For essay questions:
    #    question_id => answer text

    submission = QuizSubmission.find params[:id]
    last_updated_at = submission.updated_at

    if params[:submission].instance_of? ActionController::Parameters
      ActiveRecord::Base.transaction do
        params[:submission].to_unsafe_h.each do |question_id, answer_param| # iterate
          quiz_question = Question.find question_id
          submission_question = QuizSubmissionQuestion.create!(
            quiz_submission_id: submission.id,
            quiz_question_id: question_id
          )

          quiz_question.create_answer! submission_question, answer_param
          quiz_question.update_points_from_submission submission_question, answer_param
        end
      end
    end

    # Update proctoring results as soon as they are available.
    #
    # TODO: If at some point vendor data will contain something else than
    # proctoring results, make sure that no data is lost here.
    if params[:vendor_data].present?
      submission.update! vendor_data: params[:vendor_data]
    end

    schedule_report = false

    # Set quiz_version_at here, because we need created_at timestamp from create action
    if params[:submitted] && !submission.submitted
      timestamp = DateTime.now.in_time_zone
      if submission.within_time_limit? timestamp
        quiz_submission_time = timestamp
      else
        quiz_submission_time = last_updated_at
      end

      submission.update! quiz_submission_time:,
        quiz_version_at: submission.quiz_access_time
      schedule_report = true
    end

    # Admin grants additional points to an already submitted quiz
    if params[:fudge_points]
      submission.update! fudge_points: params[:fudge_points]
      schedule_report = true
    end

    submission.schedule_report! if schedule_report
    submission.preaggregate_statistics!

    respond_with submission
  rescue ActiveRecord::RecordInvalid => e
    error 422, plain: e.message
  end

  def destroy
    respond_with QuizSubmission.find(params[:id]).destroy
  end

  def decorate(res)
    if res.is_a? QuizSubmission
      QuizSubmissionDecorator.new res
    else # Array || ActiveRecord::Relation
      QuizSubmissionDecorator.decorate_collection res
    end
  end

  private
  def quiz
    @quiz ||= Quiz.find params.require(:quiz_id)
  end

  def submission_params
    params.permit(:course_id, vendor_data: {})
  end
end
