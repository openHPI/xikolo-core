# frozen_string_literal: true

class QuizQuestionsController < Abstract::FrontendController
  include CourseContextHelper
  respond_to :json
  before_action :ensure_content_editor
  before_action :set_no_cache_headers

  def edit
    @item = Xikolo::Course::Item.find params[:item_id] do |i|
      raise NoMethodError unless i.content_type == 'quiz'

      @quiz = Xikolo::Quiz::Quiz.find i.content_id
    end

    @quiz_question = Xikolo::Quiz::Question.find params[:id], params: {raw: 1}
    Acfs.run

    case @quiz_question.class.name
      when 'Xikolo::Quiz::MultipleChoiceQuestion'
        @multiple_choice_question = @quiz_question
      when 'Xikolo::Quiz::MultipleAnswerQuestion'
        @multiple_answer_question = @quiz_question
      when 'Xikolo::Quiz::FreeTextQuestion'
        @free_text_question = @quiz_question
      when 'Xikolo::Quiz::EssayQuestion'
        @essay_question = @quiz_question
    end
    @quiz_question.type = @quiz_question.class.to_s.split('::').last

    render layout: false
  end

  def create
    Xikolo::Course::Item.find params[:item_id] do |i|
      raise NoMethodError unless i.content_type == 'quiz'

      @quiz = Xikolo::Quiz::Quiz.find i.content_id
    end
    Acfs.run

    klass =
      case question_type
        when :multiple_choice
          Xikolo::Quiz::MultipleChoiceQuestion
        when :multiple_answer
          Xikolo::Quiz::MultipleAnswerQuestion
        when :free_text
          Xikolo::Quiz::FreeTextQuestion
        when :essay
          Xikolo::Quiz::EssayQuestion
      end

    question = klass.new question_params.merge(params.require(:xikolo_quiz_question).permit(:text, :explanation))
    question.explanation = nil if question.explanation.blank?
    question.quiz_id = @quiz.id
    question.save!

    if params[:add_answer]
      redirect_to new_course_section_item_quiz_question_quiz_answer_path quiz_question_id: question.id
    else
      redirect_to edit_course_section_item_path(id: params[:item_id]), anchor: 'questions'
    end
  end

  def update
    question = Xikolo::Quiz::Question.find params[:id], params: {raw: 1}
    Acfs.run

    the_question_params = question_params.to_h
    the_question_params['explanation'] = nil if the_question_params['explanation'].blank?

    quiz_api.rel(:question).patch(
      the_question_params,
      params: {id: question.id}
    ).value!

    unless plausible_question_type(quiz_api.rel(:question).get({id: question.id}).value!)
      add_flash_message :error, t(:'flash.error.switch_question_to_mcq')
      review_id = question.id
    end

    redirect_to edit_course_section_item_path(id: params[:item_id], review_id:), anchor: 'questions'
  end

  def destroy
    question = Xikolo::Quiz::Question.find params[:id]
    Acfs.run
    question.delete!
    redirect_back fallback_location: root_url
  end

  def move
    question = Xikolo::Quiz::Question.find params[:id]
    Acfs.run

    # Ugly hotfix: question.type is nil and overwrites model in service
    # (type is permitted param since switch question type feature was implemented)
    question.type = question.class.to_s.split('::').last

    case params[:position]
      when 'up'
        question.update_attributes({position: question.position - 1})
      when 'down'
        question.update_attributes({position: question.position + 1})
      when 'top'
        question.update_attributes({position: 1})
      when 'bottom'
        Xikolo::Quiz::Question.where quiz_id: question.quiz_id do |quiz_questions|
          question.update_attributes({position: quiz_questions.map(&:position).max + 1})
        end
      else
        question.update_attributes({position: params[:position].to_i})
    end

    Acfs.run
    request.xhr? ? head(:ok) : redirect_to(edit_course_section_item_path(id: params[:item_id]))
  end

  private

  def question_type
    return :multiple_choice unless params[:xikolo_quiz_multiple_choice_question].nil?
    return :multiple_answer unless params[:xikolo_quiz_multiple_answer_question].nil?
    return :free_text unless params[:xikolo_quiz_free_text_question].nil?
    return :essay unless params[:xikolo_quiz_essay_question].nil?

    raise ArgumentError
  end

  def multiple_choice_question_params
    params.require(:xikolo_quiz_multiple_choice_question).permit(
      :exclude_from_recap,
      :explanation,
      :points,
      :position,
      :shuffle_answers,
      :text,
      :type
    )
  end

  def multiple_answer_question_params
    params.require(:xikolo_quiz_multiple_answer_question).permit(
      :exclude_from_recap,
      :explanation,
      :points,
      :position,
      :shuffle_answers,
      :text,
      :type
    )
  end

  def free_text_question_params
    params.require(:xikolo_quiz_free_text_question).permit(
      :exclude_from_recap,
      :explanation,
      :points,
      :position,
      :text
    )
  end

  def essay_question_params
    params.require(:xikolo_quiz_essay_question).permit(
      :text,
      :explanation,
      :points,
      :position,
      :exclude_from_recap
    )
  end

  def question_params
    case question_type
      when :multiple_choice
        multiple_choice_question_params
      when :multiple_answer
        multiple_answer_question_params
      when :free_text
        free_text_question_params
      when :essay
        essay_question_params
    end
  end

  def auth_context
    the_course.context_id
  end

  def plausible_question_type(question)
    return true if question['type'] != 'Xikolo::Quiz::MultipleChoiceQuestion'

    quiz_api.rel(:answers).get({
      question_id: question['id'],
      per_page: 250,
    }).value!.count {|answer| answer['correct'] } <= 1
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
