# frozen_string_literal: true

class AnswerController < Abstract::FrontendController
  include CourseContextHelper
  include PinboardRoutesHelper

  def edit
    @answer = Xikolo::Pinboard::Answer.find(
      params[:id],
      params: {text_purpose: 'input'}
    )
    Acfs.run
    render layout: false
  end

  def create
    if current_user.anonymous? || answer_params_with_user[:question_id].nil?
      add_flash_message :error, t(:'flash.error.login_to_proceed')
      redirect_to course_question_path(id: answer_params_with_user[:question_id])
    else
      Xikolo::Pinboard::Answer.create answer_params_with_user.merge(notification: notification_params)
      redirect_to question_path(id: answer_params_with_user[:question_id])
    end
  end

  def update
    pinboard_answer = answer
    pinboard_answer.update_attributes(answer_params)

    redirect_to question_path id: answer.question_id
  end

  def upvote
    # TODO: Refactor up- & downvote methods into one method
    # only answer if right parameters are passed
    return if params[:votable_id].nil?

    if current_user.anonymous?
      response = 'not authenticated'
    else
      vote = Xikolo::Pinboard::Vote.where(
        votable_id: params[:votable_id],
        votable_type: 'Answer',
        user_id: current_user.id
      )
      Acfs.run
      vote = vote.first # Result will only be a single vote or nil
      if vote.nil?
        vote = Xikolo::Pinboard::Vote.new(
          value: 1,
          votable_id: params[:votable_id],
          votable_type: :answer,
          user_id: current_user.id
        )
        vote.save ? response = 'success' : response = 'error'
      elsif vote.value == -1
        vote.value = 1
        vote.save ? response = 'success' : response = 'error'
      else
        response = 'already voted'
      end
    end

    answer = Xikolo::Pinboard::Answer.find params[:votable_id]
    Acfs.run # TODO: Avoid Second Acfs run
    render json: {response:, votes_sum: answer.votes, votable_id: params[:votable_id], votable_type: :answer}
  rescue
    render json: {response: 'server error'}
  end

  def downvote
    # only answer if right parameters are passed
    return if params[:votable_id].nil?

    if current_user.anonymous?
      response = 'not authenticated'
    else
      vote = Xikolo::Pinboard::Vote.where(
        votable_id: params[:votable_id],
        votable_type: 'Answer',
        user_id: current_user.id
      )
      Acfs.run
      vote = vote.first # Result will only be a single vote or nil
      if vote.nil?
        vote = Xikolo::Pinboard::Vote.new(
          value: -1,
          votable_id: params[:votable_id],
          votable_type: :answer,
          user_id: current_user.id
        )
        vote.save ? response = 'success' : response = 'error'
      elsif vote.value == 1
        vote.value = -1
        vote.save ? response = 'success' : response = 'error'
      else
        response = 'already voted'
      end
    end

    answer = Xikolo::Pinboard::Answer.find params[:votable_id]
    Acfs.run # TODO: Avoid Second Acfs run
    render json: {response:, votes_sum: answer.votes, votable_id: params[:votable_id], votable_type: :answer}
  rescue
    render json: {response: 'server error'}
  end

  def destroy
    authorize! 'pinboard.entity.delete'

    answer.delete!
    redirect_to question_path(id: answer.question_id)
  end

  def abuse_report
    answer = Xikolo::Pinboard::Answer.find params[:id]
    Acfs.run
    question_id = answer.question_id

    if current_user.logged_in?
      report = Xikolo::Pinboard::AbuseReport.new reportable_id: answer.id,
        reportable_type: 'Answer',
        user_id: current_user.id,
        url: question_url(id: question_id)

      if report.save
        add_flash_message :success, t(:'pinboard.reporting.success')
      else
        add_flash_message :error, t(:'pinboard.reporting.error')
      end
    end
    redirect_to question_path(id: question_id)
  end

  def block
    authorize! 'pinboard.entity.block'

    answer({text_purpose: 'display'}).block

    redirect_to question_path(id: answer.question_id)
  end

  def unblock
    authorize! 'pinboard.entity.block'

    answer({text_purpose: 'display'}).unblock

    redirect_to question_path(id: answer.question_id)
  end

  private

  def answer(pinboard_answer_params = nil)
    answer = Xikolo::Pinboard::Answer.find(
      params[:id],
      params: pinboard_answer_params
    )

    Acfs.run
    answer
  end

  def auth_context
    the_course.context_id
  end

  def notification_params
    # TODO: remove question_path once all consumer are rolled out
    {
      notify: true,
        question_url: question_url(id: answer_params[:question_id]),
    }
  end

  def comment_params
    p = params.require(:xikolo_pinboard_comment).permit :text, :commentable_id, :commentable_type
    p[:user_id] = current_user.id
    p
  end

  def answer_params_with_user
    answer_params.merge(user_id: current_user.id)
  end

  def answer_params
    params.require(:xikolo_pinboard_answer).permit :text, :question_id, :attachment_upload_id
  end
end
