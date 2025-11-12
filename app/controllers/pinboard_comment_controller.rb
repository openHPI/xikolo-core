# frozen_string_literal: true

class PinboardCommentController < Abstract::FrontendController
  include CourseContextHelper
  include PinboardRoutesHelper

  before_action :check_course_eligibility

  def edit
    @comment = Xikolo::Pinboard::Comment.find(
      params[:id],
      params: {text_purpose: 'input'}
    )
    Acfs.run
    render layout: false
  end

  def create
    Xikolo::Pinboard::Comment.create comment_params_with_user.merge(notification: notification_params)

    # both these id reference the QUESTION, I have no idea why...
    redirect_to question_path id: params[:answer_id] || params[:question_id]
  end

  def update
    pinboard_comment = comment
    # Ensure the commentable_type is namespaced correctly for the update action
    updated_comment_params = comment_params
    unless updated_comment_params[:commentable_type].to_s.start_with?('PinboardService::')
      updated_comment_params[:commentable_type] = "PinboardService::#{comment_params[:commentable_type]}"
    end

    pinboard_comment.update_attributes(updated_comment_params)

    redirect_to question_path id: params[:question_id] || @answer.question_id
  end

  def destroy
    authorize! 'pinboard.entity.delete'

    comment.delete!

    redirect_to question_path id: params[:question_id] || @answer.question_id
  end

  def abuse_report
    unless params[:question_id]
      answer = Xikolo::Pinboard::Answer.find params[:answer_id]
      Acfs.run
    end
    question_id = params[:question_id] || answer.question_id

    if current_user.logged_in?
      report = Xikolo::Pinboard::AbuseReport.new reportable_id: params[:id],
        reportable_type: 'PinboardService::Comment',
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

    comment({text_purpose: 'display'}).block

    redirect_to question_path id: params[:question_id] || @answer.question_id
  end

  def unblock
    authorize! 'pinboard.entity.block'

    comment({text_purpose: 'display'}).unblock

    redirect_to question_path id: params[:question_id] || @answer.question_id
  end

  def comment(pinboard_comment_params = nil)
    pinboard_comment = Xikolo::Pinboard::Comment.find(params[:id], params: pinboard_comment_params) do |resource|
      # When the +question_id+ is given, the comment is a reply to an answer, so it should be loaded as well.
      @answer = Xikolo::Pinboard::Answer.find(resource.commentable_id) unless params[:question_id]
    end

    Acfs.run
    pinboard_comment
  end

  private

  def auth_context
    the_course.context_id
  end

  def comment_params
    params.require(:xikolo_pinboard_comment).permit :text, :commentable_id, :commentable_type, :text_purpose
  end

  def comment_params_with_user
    p = comment_params
    p[:user_id] = current_user.id
    p
  end

  def notification_params
    # TODO: remove question_path once all consumer are rolled out
    {
      notify: true,
      # both these ids reference the QUESTION, I have no idea why...
      question_url: question_url(id: params[:answer_id] || params[:question_id]),
    }
  end
end
