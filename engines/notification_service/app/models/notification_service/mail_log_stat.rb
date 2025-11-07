# frozen_string_literal: true

module NotificationService
class MailLogStat # rubocop:disable Layout/IndentationWidth
  extend ActiveModel::Naming

  attr_reader :news_id, :count, :oldest, :newest, :success_count, :error_count, :disabled_count, :unique_count

  def initialize(for_news_id:)
    @news_id = for_news_id
    @count = MailLog.where(news_id: for_news_id).count
    @success_count = MailLog.where(news_id: for_news_id, state: 'success').count
    @error_count = MailLog.where(news_id: for_news_id, state: 'error').count
    @disabled_count = MailLog.where(news_id: for_news_id, state: 'disabled').count
    @unique_count = MailLog.where(news_id: for_news_id).select(:user_id).distinct.count
    oldest = MailLog.where(news_id: for_news_id).order(:created_at).limit(1).first
    @oldest = oldest[:created_at] if oldest
    newest = MailLog.where(news_id: for_news_id).order(created_at: :desc).limit(1).first
    @newest = newest[:created_at] if newest
  end

  def decorate
    MailLogStatDecorator.new self
  end
end
end
