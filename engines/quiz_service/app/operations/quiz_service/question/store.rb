# frozen_string_literal: true

module QuizService
class Question::Store < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  include PointsProcessor

  attr_reader :question

  def initialize(question, params)
    super()
    @question = question
    @params = params
  end

  def call
    saved = update

    if saved && question.previous_changes.key?('points')
      update_item_max_points question.quiz_id
    end

    question
  end

  protected

  attr_reader :text_processor, :explanation_processor

  def configure_processors!(text, explanation)
    @text_processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :quiz,
      purpose: 'quiz_question_text',
      current: question.text,
      text:,
      valid_refs: Xikolo::S3.extract_file_refs(question.text)
    text_processor.on_new {|upload| new_upload(upload) }
    @explanation_processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :quiz,
      purpose: 'quiz_question_explanation',
      current: question.explanation,
      text: explanation,
      valid_refs: Xikolo::S3.extract_file_refs(question.explanation)
    explanation_processor.on_new {|upload| new_upload(upload) }
  end

  def new_upload(upload)
    cid = UUID4(question.quiz_id).to_str(format: :base62)
    id = UUID4.new.to_str(format: :base62)
    {
      key: "quizzes/#{cid}/#{id}_#{File.basename upload.key}",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_disposition: 'inline',
      content_type: upload.content_type,
    }
  end

  def update
    if !@params.key?(:text) && !@params.key?(:explanation)
      question.update @params
    else
      text = @params.delete(:text)
      explanation = @params.delete(:explanation)
      question.assign_attributes @params
      configure_processors!(text, explanation)
      process_richtexts_and_save
    end
  end

  def process_richtexts_and_save
    text_processor.parse!
    explanation_processor.parse!
    question.text = text_processor.result
    question.explanation = explanation_processor.result
    if text_processor.valid? && explanation_processor.valid? && question.save
      text_processor.commit!
      explanation_processor.commit!
      (text_processor.obsolete_uris + explanation_processor.obsolete_uris).each do |uri|
        Xikolo::S3.object(uri).delete
      end
      true
    else
      question.validate
      text_processor.rollback!
      explanation_processor.rollback!
      text_processor.errors.each do |_url, code, _message|
        question.errors.add :text, code.to_s
      end
      explanation_processor.errors.each do |_url, code, _message|
        question.errors.add :explanation, code.to_s
      end
      false
    end
  end
end
end
