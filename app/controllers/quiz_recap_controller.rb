# frozen_string_literal: true

class QuizRecapController < Abstract::FrontendController
  include CourseContextHelper

  before_action :ensure_logged_in

  respond_to :json
  inside_course only: :index

  def index
    # Wait for the navigation and header to load
    Acfs.run

    @course_id = params[:course_id]

    render
  end

  def show
    course_id = params[:course_id]
    return render json: {error: 'course_id is required'}, status: :bad_request if course_id.blank?

    render json: {questions: fetch_questions(course_id)}, status: :ok
  end

  def review
    if params[:quiz_id] && params[:course_id]
      @item = CourseService::Item.find_by(content_id: params[:quiz_id])
      redirect_to course_item_path(course_id: params[:course_id], id: @item.lower_item_id || @item.id),
        status: :see_other
    else
      add_flash_message :error, t(:'flash.error.params_missing_learn_review')
      redirect_to recap_path, status: :see_other
    end
  end

  def course_nav_tab
    :recap if action_name == 'index'
  end

  private

  def ensure_logged_in
    return true if current_user.logged_in?

    respond_to do |format|
      format.json { head :unauthorized }
      format.html { super }
    end
  end

  def auth_context
    # show allows the course_id to be gibberish and returns an empty list of questions,
    # so we don't need to check the course context for that action
    return :root if action_name == 'show'

    if params[:course_id]
      the_course.context_id
    else
      :root
    end
  end

  def fetch_questions(course_id)
    items_by_content_id = recap_items(course_id).index_by {|item| item.content.id }

    QuizService::Question
      .includes(:answers)
      .joins(:answers)
      .where(
        quiz_id: items_by_content_id.keys,
        type: QuizService::Question::RECAP_TYPES,
        exclude_from_recap: false
      )
      .where.not(points: [nil, 0])
      .distinct
      .map do |question|
        serialize_question(
          question,
          items_by_content_id.fetch(question.quiz_id),
          course_id
        )
      end
  end

  def recap_items(course_id)
    CourseService::Item
      .all_available
      .where(
        content_type: 'QuizService::Quiz',
        exercise_type: 'selftest',
        required_item_ids: [],
        section_id: CourseService::Section.where(course_id:).select(:id)
      )
  end

  def serialize_question(question, item, course_id)
    {
      id: question.id,
      text: externalize_markup(question.text),
      points: question.points,
      type: question.type.sub(/\AQuizService::/, 'Xikolo::Quiz::'),
      referenceLink: course_item_url(course_id:, id: item.id),
      answers: question.answers.map do |answer|
        {
          id: answer.id,
          text: externalize_markup(answer.text),
          correct: answer.correct || false,
        }
      end,
    }
  end

  def externalize_markup(markup)
    Xikolo::S3.externalize_file_refs(markup, public: true)
  end
end
