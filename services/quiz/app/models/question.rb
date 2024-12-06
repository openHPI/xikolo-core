# frozen_string_literal: true

class Question < ApplicationRecord
  self.table_name = 'quiz_questions'

  delegate :url_helpers, to: 'Rails.application.routes'

  default_scope { order('position ASC') }
  has_many :answers, dependent: :destroy
  has_one :statistics, class_name: 'QuestionStatistics'
  belongs_to :quiz
  acts_as_list scope: :quiz
  has_paper_trail

  validates :type, presence: true

  before_save do
    self.explanation = nil if explanation.blank?
  end
  after_commit(on: :create) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.question.create')
  end
  after_commit(on: :update) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.question.update')
  end
  after_commit(on: :destroy) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.question.destroy')
  end
  after_commit(on: :destroy) do
    (
      Xikolo::S3.extract_file_refs(text) +
      Xikolo::S3.extract_file_refs(explanation)
    ).each do |uri|
      Xikolo::S3.object(uri).delete
    end
  end

  RECAP_TYPES = %w[MultipleChoiceQuestion MultipleAnswerQuestion].freeze

  # Can this question be used in recap mode?
  def recap?
    return false if exclude_from_recap

    RECAP_TYPES.include?(type) && points.to_d != BigDecimal('0.0') && !answers.empty?
  end

  def stats
    @stats ||= QuestionStatistics.new(question_id: id)
  end

  def update_statistics!
    question_statistics.calculate!
  end

  def question_statistics
    QuestionStatistics.find_or_create_by!(question_id: id)
  rescue ActiveRecord::RecordNotUnique
    # Retry on race condition in between find and create.
    retry
  end
end
