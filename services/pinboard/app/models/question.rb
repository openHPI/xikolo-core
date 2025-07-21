# frozen_string_literal: true

require 'digest'

class Question < ApplicationRecord
  include VotesHelper
  include QuestionsHelper
  include PostHelper
  include WorkflowActiverecord

  include Question::Search

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

    on_transition do |_from, to|
      notify_admins_of_auto_block! if to == :auto_blocked
    end
  end

  belongs_to :accepted_answer, class_name: 'Answer', optional: true
  has_many :answers
  has_many :public_answers, -> { unblocked.undeleted }, class_name: 'Answer'
  has_many :answer_comments, through: :answers, source: :comments
  has_many :public_answer_comments, through: :public_answers, source: :public_comments
  has_many :comments, as: :commentable
  has_many :public_comments, -> { unblocked.undeleted }, as: :commentable, class_name: 'Comment'
  has_many :votes, as: :votable
  has_one  :requested_user_vote,
    -> { where 'votes.user_id' => Thread.current[:requested_user_id] },
    as: :votable,
    class_name: 'Vote'
  has_many :subscriptions, dependent: :destroy
  has_many :watches
  has_one  :user_watch,
    -> { where 'watches.user_id' => Thread.current[:requested_user_id] },
    class_name: 'Watch'

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :explicit_tags, -> { order('tags.id ASC') }, association_foreign_key: 'tag_id'
  has_and_belongs_to_many :implicit_tags, -> { order('tags.id ASC') }, association_foreign_key: 'tag_id'
  has_many :abuse_reports, as: :reportable

  validates :user_id, :course_id, :text, presence: true

  after_commit(on: :create) { notify :create }
  after_commit(on: :update) { notify :update }
  before_save do |question|
    question.text_hash = Digest::SHA256.hexdigest question.text
  end
  before_update :reset_reviewed

  # These methods update some cached aggregations - no need to run validations.
  # rubocop:disable Rails/SkipsModelValidations
  def update_public_answers_count!
    update_columns public_answers_count: public_answers.count
  end

  def update_public_comments_count!
    update_columns public_comments_count: public_comments.count
  end

  def update_public_answer_comments_count!
    update_columns public_answer_comments_count: public_answer_comments.count
  end
  # rubocop:enable all

  def notify(action_sym)
    Msgr.publish(decorate.to_event, to: "xikolo.pinboard.question.#{action_sym.to_s.downcase}")
  end

  # Following line does not include questions without any votes
  # scope :order_by_votes, lambda { |direction| joins(:votes).
  #                                             group('questions.id').
  #                                             order("sum(value) #{direction.to_s}") }
  # so I used the direct sql command (I could not find rails ways for this)
  # TODO: find rails functions for this
  scope :order_by_votes, lambda {|direction|
    order Arel.sql <<~SQL.squish
      (SELECT COALESCE(sum(value), 0) FROM votes WHERE votable_id = questions.id) #{direction}, updated_at ASC
    SQL
  }

  scope :default_order, -> { order Arel.sql('sticky is true DESC') } # this handles null and false values
  scope :created_after, ->(date) { where('created_at > ?', date) }
  scope :unanswered, -> { where(accepted_answer_id: nil) }
  scope :unblocked, -> { where.not(workflow_state: %i[blocked auto_blocked]) }
  scope :undeleted, -> { where.not(deleted: true) }
  scope :for_user, ->(user_id) { user_id ? where(user_id:) : all }

  def self.by_tags(tags)
    question_ids_per_tag = tags.map do |tag_id|
      Tag.find(tag_id).questions.ids
    end

    # & on an array is set union
    where id: question_ids_per_tag.inject(:&)
  end

  def self.by_tag_names(tag_names, filter_hash)
    tag_ids = tag_names.map do |tag_name|
      tag = Tag.find_by({name: tag_name}.merge(filter_hash))
      return Question.none unless tag

      tag.id
    end

    by_tags tag_ids
  end

  def technical?
    implicit_tags.any? {|tag| tag['name'] == 'Technical Issues' }
  end

  def question_title
    title
  end

  def course_ident
    course_id
  end

  def question
    self
  end

  def attachment_url
    Xikolo::S3.object(attachment_uri).public_url if attachment_uri?
  end

  def num_replies
    public_answers_count + public_comments_count + public_answer_comments_count
  end

  def context
    TopicContext.for self
  end

  def ensure_open_context!
    return if context.open?

    errors.add :base, 'forum_closed'
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def author_id=(val)
    self.user_id = val
  end

  def meta=(val)
    return unless Hash.try_convert(val)

    self.video_timestamp = val['video_timestamp'] if val['video_timestamp']
  end

  def tags=(ary)
    # If we're dealing with an array of strings, let's look up the tags named
    # by that string value. Otherwise, fall back to Rails' default behavior.
    if String.try_convert(ary.first)
      begin
        ary = ary.map do |t|
          ExplicitTag.create_with({course_id:}).find_or_create_by! name: t.strip
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end

    super
  end

  def item_id=(val)
    return unless course_id

    TopicContext.establish! self, item_id: val
  end

  def soft_delete
    update deleted: true
    subscriptions.destroy_all
    answers.each(&:soft_delete)
    comments.each(&:soft_delete)
    self
  end

  # override helper method
  def reset_reviewed
    return unless reviewed?

    if text_changed? || title_changed?
      update! workflow_state: :new
    end
  end

  def notify_admins_of_auto_block!
    course.admins.each do |admin|
      Msgr.publish(
        {
          key: 'pinboard.blocked_item',
          receiver_id: admin['id'],
          payload: {
            item_url: Xikolo.base_url.join("courses/#{course.code}/question/#{id}"),
          },
        },
        to: 'xikolo.notification.notify'
      )
    end
  end

  private

  def course
    @course ||= Course.find(course_id)
  end
end
