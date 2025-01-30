# frozen_string_literal: true

module XMLImporter
  ##
  # Handle quiz, question, and answer creation.
  class QuizPersistence
    include PointsProcessor

    def initialize(course)
      @course = course
    end

    def persist!(quizzes)
      quizzes.each do |quiz_hash|
        next unless quiz_hash['new_record']

        create_quiz!(quiz_hash) do |quiz_id|
          Array.wrap(quiz_hash['questions']['question']).each do |question_hash|
            question = create_question!(question_hash, quiz_id)
            Array.wrap(question_hash['answers']['answer']).each do |answer_hash|
              create_answer!(answer_hash, question.id)
            end
          end
          update_item_max_points quiz_id
        end
      end
    end

    private

    def create_quiz!(quiz_hash)
      ActiveRecord::Base.transaction do
        # Create the quiz content resource.
        quiz = ::Quiz.create! quiz_params(quiz_hash)

        # Create the corresponding quiz item in xi-course.
        section = @course.find_section(quiz_hash)
        @course.create_item!({
          content_type: 'quiz',
          exercise_type: exercise_type(quiz_hash),
          title: quiz_hash['name'],
          published: quiz_hash['published'],
          show_in_nav: quiz_hash['show_in_nav'],
          content_id: quiz.id,
          section_id: section['id'],
        })

        yield quiz.id if block_given?
      end
    end

    def exercise_type(quiz_hash)
      return 'survey' if quiz_hash['survey'] == 'true'
      return 'bonus' if quiz_hash['bonus'] == 'true'
      return 'main' if quiz_hash['graded'] == 'true'

      'selftest'
    end

    def quiz_params(quiz)
      {
        instructions: quiz['instructions'].presence || 'INSERT INSTRUCTION HERE',
        time_limit_seconds: quiz['time_limit'].to_i > 0 ? quiz['time_limit'] : 1,
        unlimited_time: quiz['time_limit'].to_i == 0,
        allowed_attempts: quiz['attempts'].to_i > 0 ? quiz['attempts'] : 1,
        unlimited_attempts: quiz['attempts'].to_i == 0,
        external_ref_id: quiz['external_ref'].presence,
      }
    end

    def create_question!(question_hash, quiz_id)
      case question_hash['type']
        when 'MultipleChoice'
          ::MultipleChoiceQuestion.new question_params(question_hash)
        when 'MultipleAnswer'
          ::MultipleAnswerQuestion.new question_params(question_hash)
        when 'FreeText'
          ::FreeTextQuestion.new question_params(question_hash).except(:shuffle_answers)
        else
          raise ArgumentError.new 'Unknown question type'
      end.tap do |question|
        question.quiz_id = quiz_id
        question.save!
      end
    end

    def question_params(question_hash)
      {
        text: question_hash['text'].presence || 'ADD QUESTION TEXT',
        explanation: question_hash['explanation'],
        points: question_hash['points'],
        shuffle_answers: question_hash['shuffle_answers'],
      }
    end

    def create_answer!(answer_hash, question_id)
      case answer_hash['type']
        when 'TextAnswer'
          ::TextAnswer.new answer_params(answer_hash)
        when 'FreeTextAnswer'
          ::FreeTextAnswer.new answer_params(answer_hash)
        else
          raise ArgumentError.new 'Unknown answer type'
      end.tap do |answer|
        answer.question_id = question_id
        answer.save!
      end
    end

    def answer_params(answer_hash)
      {
        text: answer_hash['text'],
        correct: answer_hash['correct'],
        comment: answer_hash['explanation'],
      }
    end
  end
end
