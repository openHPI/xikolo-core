# frozen_string_literal: true

class QuestionsController < ApplicationController
  include LearningRoomIntegrationHelper
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # rubocop:disable Layout/LineLength
  def index
    begin
      tags = []
      tags = params[:tags].split(',') if params[:tags].present?

      if params[:section_id] == 'technical' && params[:course_id].present?
        technical_tag = ImplicitTag.find_or_create_by!(name: 'Technical Issues', course_id: params[:course_id])
        tags << technical_tag.id
        params[:section_id] = nil
        params[:without_ref_resource] = 'true'
      end
      if params[:section_id].present?
        section_tag = ImplicitTag.find_or_create_by!(name: params[:section_id], course_id: params[:course_id], referenced_resource: 'Xikolo::Course::Section')
        tags << section_tag.id
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    tags = params[:taglist].values if params[:taglist].present?

    if tags.count > 0 && params[:course_id]
      questions = Question.by_tags(tags)
    elsif params[:with_tagnames]
      questions = Question.by_tag_names(params[:with_tagnames].values, question_index_params.to_h)
    else
      questions = Question.where question_index_params
    end

    questions.where! deleted: false unless params[:deleted]
    questions = questions.unblocked unless [true, 'true'].include? params[:blocked]
    questions = filter_questions questions

    decoration_context[:collection] = true

    # Preload several relationships so that the decorator cannot trigger these
    questions = questions.includes(
      :implicit_tags,
      :explicit_tags,
      :votes,
      :watches,
      :abuse_reports
    )

    if params[:vote_value_for_user_id]
      include_vote_value_for_specific_user
      questions = questions.includes(:requested_user_vote)
    end

    if params[:watch_for_user_id]
      include_watch_for_specific_user
      questions = questions.includes(:user_watch)
    end

    # Apply default order before `#search` is applied as `#search`
    # adds an ORDER clause to sort by search result rank.
    questions = questions.default_order

    if params[:search].present?
      questions = if params[:course_id].present?
                    questions.search(
                      params[:search],
                      language: Course.find(params[:course_id]).language
                    )
                  else
                    questions.search(params[:search])
                  end
    end

    # Apply order scopes last to always have search
    # rank order first
    questions = order_questions(questions)

    respond_with questions
  end
  # rubocop:enable Layout/LineLength

  def show
    @question = Question.find(params[:id])

    raise ActiveRecord::RecordNotFound if @question.deleted && !params[:deleted]

    decoration_context[:text_purpose] = params[:text_purpose]

    include_vote_value_for_specific_user if params[:vote_value_for_user_id]
    include_watch_for_specific_user if params[:watch_for_user_id]
    respond_with(@question)
  end

  def create
    params[:question] = params[:application] if params[:application].present? # workaround for sdtrange
    @question = Question.new question_params.slice(:course_id)
    @question.id = SecureRandom.uuid

    @question.tags = [].tap do |tags|
      tags.concat find_or_create_tags(tag_names) unless tag_names.empty?
      tags.concat find_implicit_tags(question_implicit_tags) unless question_implicit_tags.empty?
    end

    @question.ensure_open_context!

    @question = Commentable::Store.call @question, question_params
    raise ActiveRecord::RecordInvalid.new @question if @question.errors.any?

    unless @question.blocked?
      user = Xikolo.api(:account).value.rel(:user).get(id: @question.user_id)

      course = Xikolo.api(:course).value.rel(:course).get(id: @question.course_id).value!

      collab_space = {}
      if @question.learning_room_id.present?
        collab_space = Xikolo.api(:collabspace).value.rel(:collab_space).get(id: @question.learning_room_id).value!
      end

      Xikolo.api(:notification).value.rel(:events).post(
        key: @question.discussion_flag ? 'pinboard.discussion.new' : 'pinboard.question.new',
        payload: {
          user_id: @question.user_id,
          username: user.value!['name'],
          question_id: @question.id,
          title: @question.title,
          thread_title: @question.title,
          text: @question.text,
          course_code: course['course_code'],
          course_name: course['title'],
          learning_room_name: collab_space['name'],
        },
        public: @question.learning_room_id.blank?,
        course_id: @question.course_id,
        learning_room_id: @question.learning_room_id,
        link: expand_question_url(@question),
        subscribers: @question.subscriptions.pluck(:user_id)
      ).value!
    end
    respond_with(@question)
  rescue ActiveRecord::RecordNotUnique
    @question.errors.add(:base, 'Question already exists.')
    render status: :unprocessable_entity, json: {errors: @question.errors}
  end

  def update
    question = Question.find params[:id]

    question.review! if params[:workflow_state] == 'reviewed'
    question.block! if params[:workflow_state] == 'blocked'

    if params.key?(:tag_names)
      question.tags = if params[:implicit_tags]
                        find_implicit_tags params[:implicit_tags]
                      else
                        question.implicit_tags
                      end
      question.tags |= find_or_create_tags params[:tag_names]
    end

    # Accept answer only if it exists
    if Answer.exists? question_params[:accepted_answer_id]
      question.accepted_answer_id = question_params[:accepted_answer_id]
    end

    respond_with Commentable::Store.call(question,
      question_params.except(:accepted_answer_id))
  end

  def destroy
    respond_with Question.find(params[:id]).soft_delete
  end

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def expand_question_url(question)
    if params[:question_url]
      template = Addressable::Template.new(params[:question_url])
      template.expand(id: question.id).to_s
    end
  end

  def include_vote_value_for_specific_user
    decoration_context[:vote_value] = true
    Thread.current[:requested_user_id] = params[:vote_value_for_user_id]
  end

  def include_watch_for_specific_user
    decoration_context[:user_watch] = true
    Thread.current[:requested_user_id] = params[:watch_for_user_id]
  end

  def find_or_create_tags(tag_names)
    tag_names.map do |tag_name|
      # TODO: Make this case insensitive
      ExplicitTag.create_with(belonging_resource_hash).find_or_create_by! name: tag_name.strip
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def find_implicit_tags(implicit_tags)
    implicit_tags.compact_blank.map do |tag_id|
      ImplicitTag.find tag_id # '' for removing implicit tags
    end
  end

  def question_params
    # if we want to have questions attached to only the learning_room not the
    # courses, then we can not require there to be a course_id
    params.permit(:id, :title, :text, :video_timestamp, :video_id, :user_id,
      :accepted_answer_id, :course_id, :learning_room_id, :created_at,
      :updated_at, :discussion_flag, :attachment_upload_id, :sticky, :deleted,
      :closed)
  end

  def tag_names
    params[:tag_names] || []
  end

  def question_implicit_tags
    params.permit(implicit_tags: []).fetch :implicit_tags, []
  end

  def question_index_params
    # taglist can't be in the list here, since you can't whitelist a whole
    # hash (unfortunately)
    p = params.permit(:course_id, :learning_room_id).transform_values {|v| v.empty? ? nil : v }
    p[:learning_room_id] = nil unless p.key? 'learning_room_id'
    p
  end

  def order_questions(questions)
    case params[:question_filter_order]
      when 'age'
        questions.order(created_at: :desc)
      when 'votes'
        questions.order_by_votes :desc
      when 'random'
        questions.order(Arel.sql('RANDOM()')) # Postgres-specific

      # TODO: Add more options here! such as by votes, views...
      else # 'activity'
        questions.order(updated_at: :desc) # latest activity first is default
    end
  end

  def filter_questions(questions)
    if params[:created_after].present?
      questions = questions.created_after params[:created_after]
    end

    questions = questions.unanswered if params[:unanswered] == 'true'
    questions.where! user_id: params[:user_id] if params[:user_id]

    # Filter questions with tags without referenced resource (e.g. technical issues)
    if params[:without_ref_resource] != 'true'
      questions.where!(
        "id NOT IN
          (SELECT question_id
          FROM questions_tags JOIN tags ON questions_tags.tag_id=tags.id
          WHERE tags.type='ImplicitTag' AND
            (tags.referenced_resource IS NULL OR tags.referenced_resource=''))"
      )
    end

    questions
  end
end
# rubocop:enable all
