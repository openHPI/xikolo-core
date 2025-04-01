# frozen_string_literal: true

class QuestionController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper
  include PinboardRoutesHelper
  include Collabspace::CollabspacesIntegrationHelper

  inside_course

  before_action :ensure_logged_in
  before_action :ensure_pinboard_enabled
  before_action :check_course_path, only: :show

  before_action only: %i[edit update] do
    ensure_has_edit_rights
  end
  before_action :load_section_nav
  before_action :ensure_collabspace_membership

  helper_method :can_edit?
  helper_method :can_delete?

  # GET /question/1
  # GET /question/1.xml
  def show
    @question = Xikolo::Pinboard::Question.find(
      params[:id],
      params: {
        watch_for_user_id: current_user.id,
        vote_value_for_user_id: current_user.id,
      }
    ) do |question|
      question.enqueue_comments({
        watch_for_user_id: current_user.id,
        blocked: current_user.allowed?('pinboard.entity.block'),
      }, &:enqueue_author)
      question.enqueue_explicit_tags
      question.enqueue_section do |section|
        @section = section
      end
      question.enqueue_item
      question.enqueue_author
      question.enqueue_answers(
        sort: 'created_at',
        watch_for_user_id: current_user.id,
        vote_value_for_user_id: current_user.id,
        blocked: current_user.allowed?('pinboard.entity.block')
      ) do |answer|
        answer.enqueue_author
        answer.enqueue_comments({
          watch_for_user_id: current_user.id,
          blocked: current_user.allowed?('pinboard.entity.block'),
        }, &:enqueue_author)
      end
    end
    @subscription = load_subscription

    # the double Acfs.run call is not a mistake - acfs seems to have some
    # problems sometimes executing all callbacks... so we need to do this here
    # otherwise we do not have sections... :-<
    Acfs.run
    Acfs.run
    read_question

    if @question.learning_room_id
      @course_id = the_course.id
    else
      @course_id = @question.course_id
    end

    # Lanalytics
    gon.question_id = @question.id

    @new_comment = Xikolo::Pinboard::Comment.new
    @new_answer = Xikolo::Pinboard::Answer.new
    @new_question = Xikolo::Pinboard::Question.new
    @implicit_tags = params[:section_id] if params[:section_id]
    @show_close_button = !@question.closed && current_user.allowed?('pinboard.question.close')

    @pinboard_user_state = PinboardUserStatePresenter.new question: @question, user: current_user

    @pinboard = PinboardPresenter.new(
      course: the_course,
      section: @section,
      technical_issues: @question.technical?,
      collab_space: @collabspace
    )

    if @question.deleted == true && !current_user.allowed?('pinboard.entity.delete')
      raise Acfs::ResourceNotFound
    end

    set_page_title @question.title

    if feature? 'new_pinboard.phase-1.2'
      render 'question/new/show', layout: 'course_area_two_cols'
    else
      render layout: 'course_area_two_cols'
    end
  end

  def edit
    @question = Xikolo::Pinboard::Question.find(
      params[:id],
      params: {text_purpose: 'input'},
      &:enqueue_explicit_tags
    )
    @implicit_tags = all_implicit_tags
    Acfs.run

    render layout: false
  end

  def all_implicit_tags
    implicit_tags = []

    sections = course_api.rel(:sections).get({
      course_id: the_course.id,
      include_alternatives: true,
    }).value!
    sections.map do |section|
      pinboard_api.rel(:implicit_tags).get({
        name: section['id'],
        course_id: the_course.id,
        referenced_resource: 'Xikolo::Course::Section',
      }).then do |t|
        implicit_tags << [section['title'], t.first['id']]
      end
    end.map(&:value!)

    unless Xikolo.config.disable_technical_issues_section
      pinboard_api.rel(:implicit_tags).get({
        name: 'Technical Issues',
        course_id: the_course.id,
      }).then do |tags|
        implicit_tags.unshift [t(:'pinboard.filters.technical_issues'), tags.first['id']]
      end.value
    end

    implicit_tags
  end

  def create
    @question = Xikolo::Pinboard::Question.create(
      question_params_with_user.merge(notification_params)
    )
    redirect_to :pinboard_index
  end

  def update
    question = get_question params[:id]
    Acfs.run

    question.update_attributes(question_params)

    redirect_to question_path id: question.id
  end

  def upvote
    # only answer if right parameters are passed
    unless params[:votable_id].nil?
      if current_user.anonymous?
        response = 'not authenticated'
      else
        vote = Xikolo::Pinboard::Vote.new(
          value: 1,
          votable_id: params[:votable_id],
          votable_type: :question,
          user_id: current_user.id
        )
        vote.save ? response = 'success' : response = 'already voted'
      end

      votes_sum = sum_votes(params[:votable_id], Xikolo::Pinboard::Question)
      render json: {
        response:,
        votes_sum:,
        votable_id: params[:votable_id],
        votable_type: :question,
      }
    end
  rescue
    render json: {
      response: 'server error',
    }
  end

  def accept_answer
    question = Xikolo::Pinboard::Question.find(params[:id])
    Acfs.run
    if can_edit? question
      question.accepted_answer_id = params[:accepted_answer_id]
      question.implicit_tags = nil # Leave implicit tags unchanged
      question.save

      # send data to analytics
      data = {
        id:           question.accepted_answer_id,
        user_id:      current_user.id,
        course_id:    question.course_id,
        question_id:  question.id,
        created_at:   DateTime.now.in_time_zone,
      }

      Msgr.publish data, to: 'xikolo.pinboard.answer.accept'
    end

    head :created
  end

  def destroy
    authorize! 'pinboard.entity.delete'

    question = Xikolo::Pinboard::Question.find(params[:id])
    Acfs.run
    question.delete!
    redirect_to :pinboard_index
  end

  def close
    authorize! 'pinboard.question.close'

    question = Xikolo::Pinboard::Question.find(params[:id])
    Acfs.run
    question.update_attributes!({closed: true, implicit_tags: nil})

    if in_section_context?
      redirect_to course_section_question_path(section_id: params[:section_id], id: question.id)
    else
      redirect_to course_question_path(id: question.id)
    end
  end

  def reopen
    authorize! 'pinboard.question.close'

    question = Xikolo::Pinboard::Question.find(params[:id])
    Acfs.run
    question.update_attributes!({closed: false, implicit_tags: nil})

    if in_section_context?
      redirect_to course_section_question_path(section_id: params[:section_id], id: question.id)
    else
      redirect_to course_question_path(id: question.id)
    end
  end

  def abuse_report
    if current_user.logged_in?
      report = Xikolo::Pinboard::AbuseReport.new(
        reportable_id: params[:id],
        reportable_type: 'Question',
        user_id: current_user.id,
        url: question_url
      )
      if report.save
        add_flash_message :success, t(:'pinboard.reporting.success')
      else
        add_flash_message :error, t(:'pinboard.reporting.error')
      end
    end
    redirect_to question_path
  end

  def block
    authorize! 'pinboard.entity.block'

    question = Xikolo::Pinboard::Question.find(params[:id], params: {text_purpose: 'display'})
    Acfs.run
    question.block

    if in_section_context?
      redirect_to course_section_question_path(section_id: params[:section_id], id: question.id)
    else
      redirect_to course_question_path(id: question.id)
    end
  end

  def unblock
    authorize! 'pinboard.entity.block'

    question = Xikolo::Pinboard::Question.find(params[:id], params: {text_purpose: 'display'})
    Acfs.run
    question.unblock

    if in_section_context?
      redirect_to course_section_question_path(section_id: params[:section_id], id: question.id)
    else
      redirect_to course_question_path(id: question.id)
    end
  end

  private

  def check_course_path
    Acfs.on the_course, Xikolo::Pinboard::Question.find(params[:id]) do |course, question|
      if question.course_id != course.id
        raise Status::NotFound
      end
    end
  end

  def notification_params
    {
      question_url: partial_question_url,
    }
  end

  def partial_question_url
    # expand the URI template for questions as far as possible
    # params that are not present (e.g. section_id) are ignored
    question_url_rfc6570.partial_expand(
      course_id: params[:course_id],
      section_id: params[:section_id],
      learning_room_id: params[:learning_room_id]
    ).to_s
  end

  def auth_context
    the_course.context_id
  end

  def question_params_with_user
    question_params.merge(user_id: current_user.id)
  end

  def question_params
    p = params.require(:xikolo_pinboard_question).permit(
      :attachment_upload_id,
      :closed,
      :course_id,
      :implicit_tags,
      :learning_room_id,
      :sticky,
      :text,
      :title,
      :user_id,
      tag_names: []
    ).to_h
    p[:tag_names] ||= []
    p[:tag_names].compact_blank!

    # remove sticky attribute if user doesn't have permission for sticky posts
    p.except!(:sticky) unless current_user.allowed? 'pinboard.question.sticky'

    if p[:implicit_tags].blank? # Leave implicit tags unchanged
      p[:implicit_tags] = nil
    elsif p[:implicit_tags] == 'general' # Remove implicit tags
      p[:implicit_tags] = ['']
    else
      p[:implicit_tags] = p[:implicit_tags].split(',')
    end

    p[:course_id] = the_course.id # TODO: solve better
    p
  end

  def comment_params
    p = params.require(:xikolo_pinboard_comment).permit(
      :commentable_id,
      :commentable_type,
      :text
    )
    p[:user_id] = current_user.id
    p
  end

  def load_subscription
    Xikolo::Pinboard::Subscription.find_by(
      user_id: current_user.id,
      question_id: params[:id]
    )
  end

  def sum_votes(id, type)
    votable = type.find id
    Acfs.run
    votable.votes
  end

  def can_edit?(pinboard_item)
    current_user.allowed?('pinboard.entity.edit') || pinboard_item.user_id == current_user.id
  end

  def can_delete?
    current_user.allowed? 'pinboard.entity.delete'
  end

  def ensure_pinboard_enabled
    return if in_learning_room_context?

    raise AbstractController::ActionNotFound unless the_course.pinboard_enabled
  end

  def ensure_has_edit_rights
    question = get_question params[:id]
    Acfs.run
    unless can_edit? question
      add_flash_message :error, t(:'flash.error.pinboard.cannot_edit_question')
      redirect_to root_url
    end
  end

  def get_question(_id, &)
    @question ||= Xikolo::Pinboard::Question.find params[:id]
    Acfs.add_callback(@question, &)
    @question
  end

  def read_question
    data = {
      user_id: current_user.id,
      question_id: params[:id],
      timestamp:    Time.zone.now,
    }

    Msgr.publish data, to: 'xikolo.pinboard.read_question'
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def pinboard_api
    @pinboard_api ||= Xikolo.api(:pinboard).value!
  end
end
# rubocop:enable all
