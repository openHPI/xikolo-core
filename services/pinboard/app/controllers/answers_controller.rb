# frozen_string_literal: true

class AnswersController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # GET /answers
  # GET /answers.json
  def index
    answers = case params[:sort]
                when 'created_at'
                  Answer.order_chronologically
                when 'votes', nil
                  Answer.order_by_votes(:desc)
                else
                  return error :bad_request, json: {error: 'invalid_sort_order'}
              end

    answers.where! deleted: false unless params[:deleted]
    answers.where! question_id: params[:question_id] if params[:question_id]
    answers.where! user_id: params[:user_id] if params[:user_id]
    answers = answers.unblocked unless [true, 'true'].include? params[:blocked]

    if params[:vote_value_for_user_id]
      include_vote_value_for_specific_user
      answers = answers.includes :requested_user_vote
    end

    if params[:watch_for_user_id]
      include_watch_for_specific_user
      answers = answers.includes question: :user_watch
    end
    respond_with answers
  end

  # GET /answers/1
  # GET /answers/1.xml
  def show
    @answer = Answer.find(params[:id])
    include_vote_value_for_specific_user if params[:vote_value_for_user_id]
    decoration_context[:text_purpose] = params[:text_purpose]
    respond_with(@answer)
  end

  # POST /answers
  # POST /answers.xml
  def create
    params[:answer] = params[:application] if params[:application].present? # workaround
    question = Question.find answers_params[:question_id]
    create_answer_for question
  end

  def create_answer_for(question)
    question.ensure_open_context!

    @answer = Commentable::Store.call Answer.new, answers_params

    if @answer.errors.empty?
      # Refresh updated_at of question to indicate action
      question.touch # rubocop:disable Rails/SkipsModelValidations

      if params[:notification] && params[:notification][:notify]
        notify_subscribers question, @answer, params[:notification]
      end
    end

    respond_with @answer
  end

  def notify_subscribers(question, answer, opts = {})
    return if answer.blocked?

    user = Xikolo.api(:account).value.rel(:user).get(id: @answer.user_id)

    course = Xikolo.api(:course).value.rel(:course).get(id: question.course_id).value!

    collab_space = {}
    if question.learning_room_id.present?
      collab_space = Xikolo.api(:collabspace).value.rel(:collab_space).get(id: question.learning_room_id).value!
    end

    Xikolo.api(:notification).value.rel(:events).post(
      key: 'pinboard.question.answer.new',
      payload: {
        user_id: @answer.user_id,
        username: user.value!['name'],
        topic_id: @answer.question_id,
        topic_title: question.title,
        topic_author_id: question.user_id,
        comment_id: @answer.id,
        text: @answer.text,
        course_code: course['course_code'],
        course_name: course['title'],
        collab_space_name: collab_space['name'],

        # @deprecated fields
        question_id: @answer.question_id,
        thread_title: question.title,
        learning_room_name: collab_space['name'],
      },
      public: question.learning_room_id.blank?,
      course_id: question.course_id,
      learning_room_id: question.learning_room_id,
      link: opts[:question_url],
      subscribers: question.subscriptions.pluck(:user_id)
    ).value!
  end

  def update
    answer = Answer.find params[:id]

    answer.review! if params[:workflow_state] == 'reviewed'
    answer.block! if params[:workflow_state] == 'blocked'

    respond_with Commentable::Store.call(answer, answers_params)
  end

  def destroy
    respond_with Answer.find(params[:id]).soft_delete
  end

  def decoration_context
    @decoration_context ||= {}
  end

  def max_per_page
    250
  end

  private

  def include_vote_value_for_specific_user
    decoration_context[:vote_value] = true
    Thread.current[:requested_user_id] = params[:vote_value_for_user_id]
  end

  def include_watch_for_specific_user
    decoration_context[:user_watch] = true
    Thread.current[:requested_user_id] = params[:watch_for_user_id]
  end

  def answers_params
    params.permit(:text, :question_id, :user_id, :id,
      :attachment_upload_id, :created_at, :updated_at)
  end
end
