# frozen_string_literal: true

module NewsService
class AnnouncementDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  include Rails.application.routes.url_helpers

  delegate_all

  def as_json(opts = {})
    fields.as_json(opts)
  end

  protected

  def fields
    {
      id:,
      author_id:,
      title: localized_subject,
      translations:,
      recipients:,
      created_at:,
      publication_channels:,
      messages_url: h.announcement_messages_path(announcement_id: id),
    }.tap do |fields|
      fields[:message_url] = h.message_path(id: message.id) if message.present?
    end
  end

  def requested_locale
    @requested_locale ||= model.language_with(context[:language])
  end

  def localized_subject
    model.translations.fetch(requested_locale)['subject']
  end

  def publication_channels
    {
      email: email_channel,
      # Adding blog post information requires a model refactoring first
      # blog: {published_at: 1.day.ago.iso8601},
    }.compact
  end

  def email_channel
    return if message.blank?

    {
      status: message.status,
      creator_id: message.creator_id,
    }
  end

  def message
    @message ||= model.messages.no_test.take
  end
end
end
