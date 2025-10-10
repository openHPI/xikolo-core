# frozen_string_literal: true

require 'markdown_service'

class Event < ApplicationRecord
  self.table_name = :events

  has_many :notifications

  validates :key, presence: true
  validates :course_id, presence: false
  validates :payload, presence: true
  validates :link, presence: false

  default_scope { order created_at: :desc }

  scope :is_public, -> { where(public: true) }

  class << self
    def for_user(user_id)
      events = Event.arel_table
      notifications = Notification.arel_table

      public_events = events[:public].eq(true)
      user_events = events[:id].in(
        notifications.where(notifications[:user_id].eq(user_id)).project(:event_id)
      )

      Event.where public_events.or user_events
    end
  end

  # Map event keys (types) to mail templates
  KEYS_TO_MAIL = {
    'pinboard.discussion.new' => 'pinboard.new_thread',
    'pinboard.question.new' => 'pinboard.new_thread',
    'pinboard.question.answer.new' => 'pinboard.new_post',
    'pinboard.discussion.comment.new' => 'pinboard.new_post',
    'pinboard.question.comment.new' => 'pinboard.new_post',
    'pinboard.question.answer.comment.new' => 'pinboard.new_post',
  }.freeze

  def send_mail?
    KEYS_TO_MAIL.key? key
  end

  def mail_template
    KEYS_TO_MAIL.fetch key
  end

  def mail_payload
    payload.merge(
      'link' => link,
      'user_name' => payload['username'], # TODO: Get rid of this duplication
      'timestamp' => created_at,
      'html' => MarkdownService.render_html(payload['text'])
    )
  end
end
