# frozen_string_literal: true

require 'quiz_service/points_processor'

module QuizImporter
  # Handle quiz, question, and answer creation.
  class Persister
    include QuizService::PointsProcessor

    def initialize(course, quizzes)
      @course = course
      @quizzes = quizzes
    end

    def persist!
      quizzes.each do |quiz_obj|
        create_quiz!(quiz_obj) do |quiz_id|
          Array.wrap(quiz_obj.questions).each do |question_obj|
            question = create_question!(question_obj, quiz_id)
            Array.wrap(question_obj.answers).each do |answer_obj|
              create_answer!(answer_obj, question.id)
            end
          end
          update_item_max_points quiz_id
        end
      end
    end

    private

    attr_reader :course, :quizzes

    def create_quiz!(quiz_obj)
      ActiveRecord::Base.transaction do
        # Create the quiz content resource.
        quiz = QuizService::Quiz.create! quiz_params(quiz_obj)

        # Create the corresponding quiz item in xi-course.
        section = find_section(quiz_obj)

        raise ProcessWorksheetError.new "Section #{quiz_obj.section} not found for quiz #{quiz_obj.name}" unless section

        create_item!(quiz_obj, quiz.id, section)

        yield quiz.id if block_given?
      end
    end

    # The item creation can fail model validations (e.g. the course already
    # has an exam). Convert the RecordInvalid into a ProcessWorksheetError so
    # the controller can surface it as a flash message instead of a 500.
    def create_item!(quiz_obj, quiz_id, section)
      CourseService::Item.create!({
        content_type: 'quiz',
        exercise_type: exercise_type(quiz_obj),
        title: quiz_obj.name,
        published: false,
        content_id: quiz_id,
        section_id: section.id,
      })
    rescue ActiveRecord::RecordInvalid => e
      raise ProcessWorksheetError.new(e.record.errors.full_messages.first)
    end

    def find_section(quiz_obj)
      section = @course.sections.order(:position)[quiz_obj.section.to_i - 1]
      return nil unless section

      if quiz_obj.subsection.to_i.positive?
        section = @course.sections
          .where(parent_id: section.id)
          .order(:position)[quiz_obj.subsection.to_i - 1]
      end

      section
    end

    def exercise_type(quiz_obj)
      return 'survey' if quiz_obj.survey
      return 'bonus' if quiz_obj.bonus
      return 'exam' if quiz_obj.final_exam
      return 'main' if quiz_obj.graded

      'selftest'
    end

    def quiz_params(quiz)
      {
        instructions: quiz.instructions.presence || 'INSERT INSTRUCTION HERE',
        time_limit_seconds: quiz.time.to_i > 0 ? quiz.time : 1,
        unlimited_time: quiz.time.to_i == 0,
        allowed_attempts: quiz.attempts.to_i > 0 ? quiz.attempts : 1,
        unlimited_attempts: quiz.attempts.to_i == 0,
        external_ref_id: quiz.external_ref.presence,
        question_pool: quiz.final_exam,
      }
    end

    def create_question!(question_obj, quiz_id)
      case question_obj.type
        when 'MultipleChoice'
          QuizService::MultipleChoiceQuestion.new question_params(question_obj)
        when 'MultipleAnswer'
          QuizService::MultipleAnswerQuestion.new question_params(question_obj)
        when 'FreeText'
          QuizService::FreeTextQuestion.new question_params(question_obj).except(:shuffle_answers)
        else
          raise ArgumentError.new 'Unknown question type'
      end.tap do |question|
        question.quiz_id = quiz_id
        question.save!
      end
    end

    def question_params(question_obj)
      {
        text: question_obj.text.presence || 'ADD QUESTION TEXT',
        explanation: question_obj.explanation,
        points: question_obj.points,
        shuffle_answers: question_obj.shuffle_answers,
        exclude_from_recap: question_obj.exclude_from_recap,
      }
    end

    def create_answer!(answer_obj, question_id)
      case answer_obj.type
        when 'TextAnswer'
          QuizService::TextAnswer.new answer_params(answer_obj)
        when 'FreeTextAnswer'
          QuizService::FreeTextAnswer.new answer_params(answer_obj).except(:correct)
        else
          raise ArgumentError.new 'Unknown answer type'
      end.tap do |answer|
        answer.question_id = question_id
        answer.save!
      end
    end

    def answer_params(answer_obj)
      {
        text: answer_obj.text,
        correct: answer_obj.correct,
        comment: answer_obj.explanation,
      }
    end
  end
end
