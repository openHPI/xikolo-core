# frozen_string_literal: true

module Bridges
  module Chatbot
    class MyQuizzesController < BaseController
      before_action :require_valid_token!

      def index
        my_quizzes = []
        Xikolo.paginate(
          course_api.rel(:items).get({
            course_id: params[:course_id],
            content_type: 'quiz',
            exercise_type: 'selftest',
            all_available: true,
            required_items: 'none',
            user_id: @user_id,
          })
        ) do |quiz|
          quiz['questions'] = quiz_api.rel(:questions).get({quiz_id: quiz['content_id']}).then do |questions|
            Restify::Promise.new(questions.map do |question|
              quiz_api.rel(:answers).get({question_id: question['id']}).then do |answers|
                question['answers'] = answers.map {|answer| serialize_answer(answer) }
                serialize_question(question)
              end
            end)
          end.value!
          my_quizzes << serialize_quiz(quiz)
        end
        render json: my_quizzes
      end

      private

      def serialize_quiz(quiz)
        {
          quiz_id: quiz['id'],
          course_id: quiz['course_id'],
          questions: quiz['questions'],
        }
      end

      def serialize_question(question)
        {
          question_id: question['id'],
          question: question['text'],
          question_points: question['points'],
          question_explanation: question['explanation'],
          question_type: question['type'],
          answers: question['answers'],
        }
      end

      def serialize_answer(answer)
        {
          answer_id: answer['id'],
          answer_text: answer['text'],
          answer_explanation: answer['comment'],
          answer_correct: answer['correct'],
        }
      end
    end
  end
end
