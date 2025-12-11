# frozen_string_literal: true

module QuizService
class Quiz::Clone < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  def initialize(quiz)
    super()
    @old_quiz = quiz
  end

  def call
    attrs = old_quiz.attributes.dup
    attrs['id'] = @new_quiz_id = SecureRandom.uuid
    attrs['instructions'] = copy_files old_quiz.instructions
    @new_quiz = Quiz.create attrs
    clone_content!
    new_quiz
  end

  private

  attr_reader :old_quiz, :new_quiz, :new_quiz_id

  def clone_content!
    old_quiz.questions.each do |old_question|
      attrs = old_question.attributes.except('id')
      attrs['quiz_id'] = new_quiz.id
      attrs['text'] = copy_files old_question.text
      attrs['explanation'] = copy_files old_question.explanation
      new_question = old_question.class.create attrs
      old_question.answers.each do |old_answer|
        attrs = old_answer.attributes.except('id')
        attrs['question_id'] = new_question.id
        attrs['text'] = copy_files old_answer.text
        old_answer.class.create attrs
      end
    end
  end

  def copy_files(markup)
    @file_cache ||= {}
    markup&.gsub(Xikolo::S3.url_regex) do |match|
      next @file_cache[match] if @file_cache.key? match

      original = Xikolo::S3.object(match)
      # Replace quiz ID in key
      key = original.key.split('/').tap do |parts|
        parts[1] = UUID4(new_quiz_id).to_s(format: :base62)
      end.join('/')

      @file_cache[match] = Xikolo::S3.copy_to(original, target: key, bucket: :quiz, acl: 'public-read')
    end
  end
end
end
