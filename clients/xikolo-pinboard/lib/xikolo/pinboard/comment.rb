# frozen_string_literal: true

class Xikolo::Pinboard::Comment < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'comments'

  attribute :id, :uuid
  attribute :text, :string
  attribute :user_id, :uuid
  attribute :commentable_id, :uuid
  attribute :commentable_type, :string
  attribute :created_at, :string
  attribute :updated_at, :string
  attribute :deleted, :boolean, default: false
  attribute :abuse_report_state, :string
  attribute :abuse_report_count, :integer
  attribute :read, :boolean

  def enqueue_author(&)
    @author = Xikolo::Account::User.find(user_id, &)
  end

  attr_reader :author

  def report(user_id)
    Xikolo::Pinboard::AbuseReport.create reportable_id: id,
      reportable_type: 'Comment',
      user_id:
  end

  def block
    update_attributes({workflow_state: 'blocked'})
  end

  def unblock
    update_attributes({workflow_state: 'reviewed'})
  end

  def blocked?
    %w[blocked auto_blocked].include? abuse_report_state
  end

  def reviewed?
    abuse_report_state == 'reviewed'
  end
end
