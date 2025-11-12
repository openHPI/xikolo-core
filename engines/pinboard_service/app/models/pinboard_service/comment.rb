# frozen_string_literal: true

module PinboardService
class Comment < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :comments

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
      update_question_stats!
    end

    on_transition do |_from, to|
      commentable.question.notify_admins_of_auto_block! if to == :auto_blocked
    end
  end

  belongs_to :commentable, polymorphic: true
  belongs_to :answer, -> { where(comments: {commentable_type: 'PinboardService::Answer'}) },
    foreign_key: 'commentable_id',
    optional: true
  belongs_to :question, -> { where(comments: {commentable_type: 'PinboardService::Question'}) },
    foreign_key: 'commentable_id',
    optional: true
  has_many :votes, as: :votable
  has_many :abuse_reports, as: :reportable

  scope :default_order, -> { order :created_at }
  scope :unblocked, -> { where.not(comments: {workflow_state: %i[blocked auto_blocked]}) }
  scope :undeleted, -> { where.not(comments: {deleted: true}) }
  scope :for_user, ->(user_id) { user_id ? where(user_id:) : all }

  delegate :course_id, to: :commentable, allow_nil: true
  delegate :technical?, to: :commentable, allow_nil: true

  validates :user_id, presence: true

  after_create { Msgr.publish(decorate.to_event, to: 'xikolo.pinboard.comment.create') }
  after_update { Msgr.publish(decorate.as_json, to: 'xikolo.pinboard.comment.update') }
  before_update :reset_reviewed

  after_save do |comment|
    comment.update_question_stats!
  end

  after_destroy do |comment|
    comment.update_question_stats!
  end

  def update_question_stats!
    case commentable_type
      when 'Question'
        commentable.update_public_comments_count!
      when 'Answer'
        commentable.question.update_public_answer_comments_count!
    end
  end

  def question_title
    commentable.question_title
  end

  def course_ident
    commentable.course_ident
  end

  def soft_delete
    update! deleted: true
    self
  end

  def question_id
    case commentable_type
      when 'Question'
        commentable.id
      when 'Answer'
        commentable.question_id
    end
  end
end
end
