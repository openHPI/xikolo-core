# frozen_string_literal: true

class Quiz::Store < ApplicationOperation
  attr_reader :quiz

  def initialize(quiz, params)
    super()
    @quiz = quiz
    @params = params
  end

  def call
    update

    quiz
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :quiz,
      purpose: 'quiz_quiz_instructions',
      current: quiz.instructions,
      text: input,
      valid_refs: Xikolo::S3.extract_file_refs(quiz.instructions)
    processor.on_new do |upload|
      cid = UUID4(quiz.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "quizzes/#{cid}/#{id}_#{File.basename upload.key}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
  end

  def update
    if @params.key?(:instructions)
      instructions = @params.delete(:instructions)
      quiz.assign_attributes @params
      configure_processor! instructions
      process_richinstructions_and_save
    else
      quiz.update @params
    end
  end

  def process_richinstructions_and_save
    processor.parse!
    quiz.instructions = processor.result
    if processor.valid? && quiz.save
      processor.commit!
      processor.obsolete_uris.each do |uri|
        Xikolo::S3.object(uri).delete
      end
      true
    else
      quiz.validate
      processor.rollback!
      processor.errors.each do |_url, code, _message|
        quiz.errors.add :instructions, code.to_s
      end
      false
    end
  end
end
