# frozen_string_literal: true

class Answer::Store < ApplicationOperation
  attr_reader :answer

  def initialize(answer, params)
    super()
    @answer = answer
    @params = params
  end

  def call
    update

    answer
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :quiz,
      purpose: 'quiz_answer_text',
      current: answer.text,
      text: input,
      valid_refs: Xikolo::S3.extract_file_refs(answer.text)
    processor.on_new do |upload|
      cid = UUID4(answer.question.quiz_id).to_str(format: :base62)
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
    if @params.key?(:text)
      text = @params.delete(:text)
      answer.assign_attributes @params
      configure_processor! text
      process_richtext_and_save
    else
      answer.update @params
    end
  end

  def process_richtext_and_save
    processor.parse!
    answer.text = processor.result
    if processor.valid? && answer.save
      processor.commit!
      processor.obsolete_uris.each do |uri|
        Xikolo::S3.object(uri).delete
      end
      true
    else
      answer.validate
      processor.rollback!
      processor.errors.each do |_url, code, _message|
        answer.errors.add :text, code.to_s
      end
      false
    end
  end
end
