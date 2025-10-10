# frozen_string_literal: true

class Answer < ApplicationRecord
  self.table_name = :answers

  include VotesHelper
  include PostHelper
  include WorkflowActiverecord

  include Question::SearchResource

  workflow do
    state :new do
      event :report, transitions_to: :reported
      event :review, transitions_to: :reviewed
      event :block, transitions_to: :blocked
    end

    state :reported do
      event :report, transitions_to: :auto_blocked, if: proc {|r| r.report_threshold_reached? }
      event :report, transitions_to: :reported
      event :review, transitions_to: :reviewed
      event :block, transitions_to: :blocked
    end

    state :auto_blocked do
      event :report, transitions_to: :auto_blocked
      event :review, transitions_to: :reviewed
      event :block, transitions_to: :blocked
    end

    state :blocked do
      event :report, transitions_to: :blocked
      event :review, transitions_to: :reviewed
      event :block, transitions_to: :blocked
    end

    state :reviewed do
      event :report, transitions_to: :reviewed
      event :review, transitions_to: :reviewed
      event :block, transitions_to: :blocked
    end

    after_transition do
      question.update_public_answers_count!
    end

    on_transition do |_from, to|
      question.notify_admins_of_auto_block! if to == :auto_blocked
    end
  end

  belongs_to :question, touch: true

  has_many :comments, as: :commentable
  has_many :public_comments, -> { unblocked.undeleted }, class_name: 'Comment', as: :commentable
  has_many :votes, as: :votable
  has_one  :requested_user_vote,
    -> { where 'votes.user_id' => Thread.current[:requested_user_id] },
    as: :votable,
    class_name: 'Vote'
  has_one :user_watch, through: :question
  has_many :abuse_reports, as: :reportable

  delegate :course_id, to: :question, allow_nil: true
  delegate :technical?, to: :question, allow_nil: true

  validates :user_id, presence: true

  scope :order_by_votes, lambda {|direction|
    order Arel.sql <<~SQL.squish
      (SELECT COALESCE(sum(value), 0) FROM votes WHERE votable_id = answers.id) #{direction}, updated_at ASC
    SQL
  }
  scope :order_chronologically, -> { order :created_at }

  scope :unblocked, -> { where.not(workflow_state: %i[blocked auto_blocked]) }
  scope :undeleted, -> { where.not(deleted: true) }
  scope :for_user, ->(user_id) { user_id ? where(user_id:) : all }
  after_create { Msgr.publish(decorate.to_event, to: 'xikolo.pinboard.answer.create') }
  after_update { Msgr.publish(decorate.as_json, to: 'xikolo.pinboard.answer.update') }
  before_update :reset_reviewed

  after_save do |answer|
    answer.question.update_public_answers_count!
  end

  after_destroy do |answer|
    answer.question.update_public_answers_count!
  end

  def question_title
    question.title
  end

  def course_ident
    question.course_ident
  end

  def soft_delete
    update! deleted: true
    comments.each(&:soft_delete)
    self
  end

  def attachment_url
    Xikolo::S3.object(attachment_uri).public_url if attachment_uri?
  end
end
