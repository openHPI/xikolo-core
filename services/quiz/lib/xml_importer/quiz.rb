# frozen_string_literal: true

module XmlImporter
  ##
  # Handle the entire process of importing quizzes from an XML string.
  # Responsibilities include validating the XML schema, preprocessing quizzes
  # to make sure all section and course data matches, detecting new records,
  # and eventually creating quizzes, questions, and answers.
  class Quiz
    def initialize(required_course_code, course_id, xml_string)
      @xml_string = xml_string
      @course_code = required_course_code

      @course = Course.new(course_id)
    end

    def preprocess!
      XmlValidator.new(@xml_string).validate!

      quizzes_hash = Hash.from_trusted_xml(@xml_string)
      quizzes = Array.wrap(quizzes_hash['quizzes']['quiz'])
      QuizValidator.new(@course, @course_code).validate!(quizzes)

      mark_new_records!(quizzes)

      quizzes_hash
    end

    def create_quizzes!
      quizzes_hash = preprocess!
      quizzes = Array.wrap(quizzes_hash['quizzes']['quiz'])

      QuizPersistence.new(@course).persist!(quizzes)
    end

    private

    # Detect existing quiz records, so they are not created twice or updated
    # incorrectly.
    def mark_new_records!(quizzes)
      external_ref_ids = ::Quiz.where(id: @course.course_item_ids)
        .find_in_batches(batch_size: 50)
        .flat_map {|quiz_batch| quiz_batch.pluck(:external_ref_id) }

      quizzes.each do |quiz|
        quiz['new_record'] = if quiz['external_ref'].present?
                               external_ref_ids.exclude?(quiz['external_ref'])
                             else
                               true
                             end
      end
    end
  end
end
