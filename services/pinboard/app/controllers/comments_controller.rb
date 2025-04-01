# frozen_string_literal: true

class CommentsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # GET /comments
  # GET /comments.xml
  def index
    comments = Comment.default_order.includes(:abuse_reports)
    comments.where! deleted: false unless params[:deleted]
    comments.where! user_id: params[:user_id] if params[:user_id]
    comments = comments.unblocked unless [true, 'true'].include? params[:blocked]

    if params[:watch_for_user_id]
      include_watch_for_specific_user
      comments = comments.includes commentable: :user_watch
    end

    if params[:commentable_type].nil?
      respond_with comments
    elsif params[:commentable_id].nil?
      respond_with comments.where commentable_type: params[:commentable_type]
    else
      respond_with comments.where \
        commentable_id: params[:commentable_id],
        commentable_type: params[:commentable_type]
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = Comment.find(params[:id])
    decoration_context[:text_purpose] = params[:text_purpose]
    respond_with(@comment)
  end

  # POST /comments
  # POST /comments.xml
  def create
    case params.require(:commentable_type).downcase
      when 'question'
        commentable = Question.find params.require(:commentable_id)
      when 'answer'
        commentable = Answer.find params.require(:commentable_id)
      else
        raise ActiveRecord::RecordNotFound
    end

    @comment = Comment.new comment_params.except(:text)
    # Refresh +updated_at+ of the question to indication action
    commentable.touch # rubocop:disable Rails/SkipsModelValidations
    commentable.question.ensure_open_context!

    @comment.commentable = commentable

    @comment = Comment::Store.call @comment, comment_params.slice(:text)

    # check for previous errors directly, as `.valid?` would clear all previously errors:
    if @comment.errors.empty? && (params[:notification] && params[:notification][:notify]) && !@comment.blocked?
      notify_subscribers commentable, @comment, params[:notification]
    end

    respond_with(@comment)
  end

  def notify_subscribers(commentable, comment, opts = {})
    return if commentable.blocked?

    if commentable.is_a? Question
      question = commentable
      event_key = question.discussion_flag ? 'pinboard.discussion.comment.new' : 'pinboard.question.comment.new'
    else # answer
      question = commentable.question
      event_key = 'pinboard.question.answer.comment.new'
    end

    user = Xikolo.api(:account).value.rel(:user).get({id: comment.user_id})
    answer_author = Xikolo.api(:account).value.rel(:user).get({id: commentable.user_id})

    course = Xikolo.api(:course).value.rel(:course).get({id: question.course_id}).value!

    collab_space = {}
    if question.learning_room_id.present?
      collab_space = Xikolo.api(:collabspace).value.rel(:collab_space).get({id: question.learning_room_id}).value!
    end

    Xikolo.api(:notification).value.rel(:events).post({
      key: event_key,
      payload: {
        user_id: comment.user_id,
        username: user.value!['name'],
        topic_id: question.id,
        topic_title: question.title,
        topic_author_id: question.user_id,
        comment_id: comment.id,
        text: comment.text,
        course_code: course['course_code'],
        course_name: course['title'],
        collab_space_name: collab_space['name'],
        answer_author_name: answer_author.value!['name'],

        # @deprecated fields
        question_id: question.id,
        thread_title: question.title,
        learning_room_name: collab_space['name'],
      },
      public: question.learning_room_id.blank?,
      course_id: question.course_id,
      learning_room_id: question.learning_room_id,
      link: opts[:question_url],
      subscribers: question.subscriptions.pluck(:user_id),
    }).value!
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    comment = Comment.find params[:id]

    comment.review! if params[:workflow_state] == 'reviewed'
    comment.block! if params[:workflow_state] == 'blocked'

    respond_with Comment::Store.call(comment, comment_params)
  end

  def destroy
    respond_with Comment.find(params[:id]).soft_delete
  end

  def max_per_page
    250
  end

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def include_watch_for_specific_user
    decoration_context[:user_watch] = true
    Thread.current[:requested_user_id] = params[:watch_for_user_id]
  end

  def comment_params
    params.permit(:text, :user_id, :commentable_id, :commentable_type, :updated_at)
  end
end
