# frozen_string_literal: true

module Processors
  class QuizProcessor < BaseProcessor
    attr_reader :course_item, :quiz, :questions

    def initialize(item)
      super

      @course_item = nil
      @quiz = nil
      @questions = nil
    end

    def load_resources!
      raise Errors::InvalidItemType unless item.content_type == 'quiz'

      quiz_api = Xikolo.api(:quiz).value!
      @course_item = Xikolo.api(:course).value!
        .rel(:item)
        .get(id: item.id)
        .value!
      @quiz = quiz_api.rel(:quiz).get(id: item.content_id).value!

      @questions = quiz_api
        .rel(:questions)
        .get(quiz_id: quiz['id'])
        .then do |questions|
        Restify::Promise.new(questions.map do |question|
          quiz_api
            .rel(:answers)
            .get(question_id: question['id'])
            .then do |answers|
            question['answers'] = answers.map do |answer|
              additional_params = {'explanation' => answer['comment']}
              answer.slice('id', 'text', 'position').merge(additional_params)
            end

            question # return value
          end
        end)
      end.value!
    rescue Restify::NotFound
      raise Errors::LoadResourcesError
    end

    def calculate
      return unless course_item.present? && quiz.present? && questions.present?

      @time_effort = (approximate_reading_time +
          (quiz_taking_time.to_f * exercise_type_multiplier)).ceil

      # Course item time limit not considered here, but might be used in
      # the frontend when showing the time needed for a course.
    end

    private

    def approximate_reading_time
      # The quiz instruction is not considered for calculation since
      texts = []
      questions.map do |question|
        texts.push question['text']
        # Question explanations are not considered here
        texts << question['answers'].pluck('text')
      end
      ItemTypes::RichText.new(texts.join('\n')).time_effort
    end

    def quiz_taking_time
      ItemTypes::Quiz.new(quiz, questions).time_effort
    end

    def exercise_type_multiplier
      # Graded exercises typically take longer since people are more careful
      # with choosing answers and also review their selections again
      return 3 if %w[main bonus].include? course_item['exercise_type']

      1
    end
  end
end
