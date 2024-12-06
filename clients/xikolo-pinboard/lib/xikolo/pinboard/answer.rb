# frozen_string_literal: true

class Xikolo::Pinboard::Answer < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'answers'

  attribute :id, :uuid
  attribute :text, :string
  attribute :question_id, :uuid
  attribute :user_id, :uuid
  attribute :created_at, :string
  attribute :updated_at, :string
  attribute :votes, :integer
  attribute :vote_value_for_requested_user, :integer
  attribute :attachment_url, :string
  attribute :deleted, :boolean, default: false
  attribute :abuse_report_state, :string
  attribute :unhelpful_answer_score, :float
  attribute :ranking, :integer
  attribute :blocked, :boolean, default: false
  attribute :abuse_report_count, :integer
  attribute :read, :boolean

  attr_reader :author, :comments

  def enqueue_author(&)
    @author = Xikolo::Account::User.find(user_id, &)
  end

  def enqueue_comments(params = {})
    @comments = []
    Xikolo::Pinboard::Comment.each_item(
      params.merge(commentable_id: id, commentable_type: 'Answer', per_page: 250)
    ) do |comment|
      @comments << comment
      yield comment if block_given?
    end
  end

  def report(user_id)
    Xikolo::Pinboard::AbuseReport.create reportable_id: id,
      reportable_type: 'Answer',
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
