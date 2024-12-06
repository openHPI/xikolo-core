# frozen_string_literal: true

module XMLImporter
  class Quiz
    QUIZ_XML_SCHEMA_FILE = 'app/assets/quiz_import_schema.xml'
    include PointsProcessor

    def initialize(required_course_code, course_id, xml_string)
      @xml_string = xml_string
      @course_id  = course_id
      @required_course_code = required_course_code
    end

    def course_sections
      @course_sections ||= course_api.rel(:sections).get(
        course_id: @course_id
      ).value!
    end

    def alternative_sections(parent_id)
      course_api.rel(:sections).get(
        course_id: @course_id,
        parent_id:
      ).value!
    end

    def preprocess
      schema_errors = validate_xml
      if schema_errors.any?
        raise ::XMLImporter::SchemaError.new schema_errors.collect(&:message)
      end

      parameter_errors = []

      quizzes_hash = Hash.from_trusted_xml(@xml_string)
      quizzes = Array.wrap(quizzes_hash['quizzes']['quiz'])
      quizzes.each do |quiz_hash|
        if find_course_section(quiz_hash).nil?
          msg = "Course section for quiz \"#{quiz_hash['name']}\" does not exist"
          parameter_errors << msg
        end

        if quiz_hash['course_code'] != @required_course_code
          msg = "Quiz \"#{quiz_hash['name']}\" has a wrong course code parameter"
          parameter_errors << msg
        end
      end

      if parameter_errors.any?
        raise ::XMLImporter::ParameterError.new parameter_errors
      end

      mark_new_record(quizzes)

      quizzes_hash
    end

    def mark_new_record(quizzes)
      section_ids = course_sections.pluck('id')

      quiz_ids = Restify::Promise.new(section_ids.map do |section_id|
        course_api.rel(:items).get(section_id:).then do |items|
          items.pluck('content_id')
        end
      end).value!

      external_ref_ids = []
      ::Quiz.where(id: quiz_ids.flatten).find_in_batches(batch_size: 50) do |quiz_batch|
        external_ref_ids << quiz_batch.pluck(:external_ref_id)
      end
      external_ref_ids.flatten!

      quizzes.each do |quiz|
        quiz['new_record'] = quiz['external_ref'].present? ? external_ref_ids.exclude?(quiz['external_ref']) : true
      end
    end

    def create_quizzes
      quizzes_hash = preprocess
      quizzes = Array.wrap(quizzes_hash['quizzes']['quiz'])
      quizzes.each do |quiz_hash|
        next unless quiz_hash['new_record']

        create_quiz(quiz_hash) do |quiz_id|
          if quiz_hash['questions']['question'].is_a? Array
            quiz_hash['questions']['question'].each do |question_hash|
              handle_question(question_hash, quiz_id)
            end
          else
            handle_question(quiz_hash['questions']['question'], quiz_id)
          end
          update_item_max_points quiz_id
        end
      end
    end

    def handle_question(question_hash, quiz_id)
      question_id = create_question(question_hash, quiz_id)
      if question_hash['answers']['answer'].is_a? Array
        question_hash['answers']['answer'].each do |answer_hash|
          create_answer(answer_hash, question_id)
        end
      else
        create_answer(question_hash['answers']['answer'], question_id)
      end
    end

    def validate_xml
      Nokogiri::XML::Schema(File.read(QUIZ_XML_SCHEMA_FILE))
        .validate(Nokogiri::XML(@xml_string))
    end

    ### Quiz begin ###
    def create_quiz(quiz_hash)
      quiz = ::Quiz.new
      quiz.update quiz_params(quiz_hash)
      quiz_id = save_quiz(quiz, quiz_hash)

      yield quiz_id
    end

    def save_quiz(quiz, quiz_hash)
      assign_quiz_item_to_section quiz, quiz_hash
      quiz.id
    end

    def find_course_section(quiz_hash)
      section = course_sections[quiz_hash['section'].to_i - 1]

      if quiz_hash['subsection'].to_i > 0
        alternative_sections = alternative_sections(section['id'])
        section = alternative_sections[quiz_hash['subsection'].to_i - 1]
      end

      section
    end

    def assign_quiz_item_to_section(quiz, quiz_hash)
      section = find_course_section(quiz_hash)
      if section.nil?
        msg = "Course section for quiz \"#{quiz_hash['name']}\" does not exist"
        raise ::XMLImporter::ParameterError.new [msg]
      end

      params = {
        content_type: 'quiz',
        exercise_type: exercise_type(quiz_hash),
        title: quiz_hash['name'],
        published: quiz_hash['published'],
        show_in_nav: quiz_hash['show_in_nav'],
        content_id: quiz.id,
        section_id: section['id'],
      }

      course_api.rel(:items).post(params).value!
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
        external_ref_id: quiz['external_ref'] || nil,
      }
    end
    #### Quiz end ####

    ### Question begin ###
    def create_question(question_hash, quiz_id)
      case question_hash['type']
        when 'MultipleChoice'
          question = ::MultipleChoiceQuestion.new(
            multiple_choice_question_params(question_hash)
          )
        when 'MultipleAnswer'
          question = ::MultipleAnswerQuestion.new(
            multiple_answer_question_params(question_hash)
          )
        when 'FreeText'
          question = ::FreeTextQuestion.new(
            free_text_question_params(question_hash)
          )
        else
          raise ArgumentError
      end

      question.quiz_id = quiz_id
      question.save!

      question.id
    end

    def free_text_question_params(question_hash)
      {
        text: question_hash['text'].presence || 'ADD QUESTION TEXT',
        explanation: question_hash['explanation'],
        points: question_hash['points'],
      }
    end

    def multiple_answer_question_params(question_hash)
      free_text_question_params(question_hash).merge(
        shuffle_answers: question_hash['shuffle_answers']
      )
    end

    def multiple_choice_question_params(question_hash)
      multiple_answer_question_params(question_hash)
    end
    ### Question end ###

    ### Answer begin ###
    def create_answer(answer_hash, question_id)
      case answer_hash['type']
        when 'TextAnswer'
          answer = ::TextAnswer.new text_quiz_answer_params(answer_hash)
        when 'FreeTextAnswer'
          answer = ::FreeTextAnswer.new text_quiz_answer_params(answer_hash)
        else
          raise ArgumentError
      end

      answer.question_id = question_id
      answer.save!
    end

    def text_quiz_answer_params(answer_hash)
      {
        text: answer_hash['text'],
        correct: answer_hash['correct'],
        comment: answer_hash['explanation'],
      }
    end

    private

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end
end
