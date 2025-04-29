# frozen_string_literal: true

class QuizRecapController < ApplicationController
  before_action :ensure_logged_in

  def show
    course_id = params[:course_id]
    return render json: {error: 'course_id is required'}, status: :bad_request if course_id.blank?

    render json: {questions: fetch_questions(course_id)}, status: :ok
  end

  private

  def ensure_logged_in
    return true if current_user.logged_in?

    head :unauthorized
  end

  def fetch_questions(course_id)
    quiz_api.rel(:questions).get({course_id:, selftests: true, exclude_from_recap: false, eligible_for_recap: true})
      .then do |questions|
        Restify::Promise.new(questions.map do |question|
          course_api.rel(:items).get({content_id: question['quiz_id']}).then do |items|
            if items.first.present?
              question['reference_link'] = course_item_url(course_id: course_id, id: items.first['id'])
            end
            serialize_question(question)
          end
        end)
      end.value!
  end

  def serialize_question(question)
    {
      id: question['id'],
      text: question['text'],
      points: question['points'],
      type: question['type'],
      referenceLink: question['reference_link'],
      answers: question['answers'].map do |answer|
        {
          id: answer['id'],
          text: answer['text'],
          correct: answer['correct'],
        }
      end,
    }.compact
  end

  def quiz_api
    Xikolo.api(:quiz).value!
  end

  def course_api
    Xikolo.api(:course).value!
  end
end
