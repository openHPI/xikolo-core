# frozen_string_literal: true

class QuizAnswersController < Abstract::FrontendController
  include CourseContextHelper
  respond_to :json
  before_action :ensure_content_editor
  before_action :set_no_cache_headers

  def new
    @quiz_question = Xikolo::Quiz::Question.find params[:quiz_question_id], &:enqueue_acfs_request_for_answers
    Acfs.run

    @quiz_answer = Xikolo::Quiz::Answer.new
    if @quiz_question.is_a? Xikolo::Quiz::FreeTextQuestion
      @text_quiz_answer = Xikolo::Quiz::FreeTextAnswer.new
    else
      @text_quiz_answer = Xikolo::Quiz::TextAnswer.new
    end
    render layout: false
  end

  def edit
    @quiz_answer = Xikolo::Quiz::Answer.find params[:id], params: {raw: 1}
    Acfs.run
    @text_quiz_answer = @quiz_answer
    render layout: false
  end

  def create
    case answer_type
      when :text_answer
        answer = Xikolo::Quiz::TextAnswer.new text_quiz_answer_params
      when :free_text_answer
        answer = Xikolo::Quiz::FreeTextAnswer.new free_text_quiz_answer_params
    end

    answer.question_id = params[:quiz_question_id]
    answer.save!

    if params[:add_answer]
      redirect_to new_course_section_item_quiz_question_quiz_answer_path
    else
      redirect_to(
        edit_course_section_item_path(
          course_id: params[:course_id],
          id: params[:item_id]
        ),
        anchor: 'questions'
      )
    end
  end

  def update
    answer = Xikolo::Quiz::Answer.find params[:id]
    Acfs.run

    case answer_type
      when :text_answer
        answer.attributes = text_quiz_answer_params
      when :free_text_answer
        answer.attributes = free_text_quiz_answer_params
    end
    answer.save!

    redirect_to edit_course_section_item_path(id: params[:item_id]), anchor: 'questions'
  end

  def move
    answer = Xikolo::Quiz::Answer.find params[:id]
    Acfs.run

    case params[:position]
      when 'up'
        answer.update_attributes({position: answer.position - 1})
      when 'down'
        answer.update_attributes({position: answer.position + 1})
      when 'top'
        answer.update_attributes({position: 1})
      when 'bottom'
        Xikolo::Quiz::Answer.where quiz_id: answer.quiz_id do |quiz_answers|
          answer.update_attributes({position: quiz_answers.map(&:position).max + 1})
        end
      else
        answer.update_attributes({position: params[:position].to_i})
    end

    Acfs.run
    request.xhr? ? head(:ok) : redirect_to(edit_course_section_item_path)
  end

  def destroy
    quiz_api.rel(:answer).delete({id: params[:id]}).value!

    add_flash_message :success, t('flash.success.quiz_answer')
  rescue Restify::ClientError
    add_flash_message :error, t('flash.error.quiz_answer')
  ensure
    redirect_to edit_course_section_item_path(id: params[:item_id]), anchor: 'questions'
  end

  private

  def auth_context
    the_course.context_id
  end

  def answer_type
    return :text_answer unless params[:xikolo_quiz_text_answer].nil?
    return :free_text_answer unless params[:xikolo_quiz_free_text_answer].nil?

    raise ArgumentError
  end

  def text_quiz_answer_params
    params
      .require(:xikolo_quiz_text_answer)
      .permit(:text, :correct, :comment)
  end

  def free_text_quiz_answer_params
    params
      .require(:xikolo_quiz_free_text_answer)
      .permit(:text, :comment)
      .tap {|p| p[:text]&.strip! }
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
