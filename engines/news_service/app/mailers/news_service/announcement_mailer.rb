# frozen_string_literal: true

module NewsService
class AnnouncementMailer < ApplicationMailer # rubocop:disable Layout/IndentationWidth
  after_action :bulk_mail_headers
  after_action :unsubscribe_header

  def announcement(message, user)
    locale = message.language_with(user['language'])
    translation = message.translations.fetch(locale)

    I18n.with_locale(locale) do
      @payload = Hashie::Mash.new(
        test: message.test,
        content: translation.fetch('content'),
        email: user.fetch('email'),
        mailheader_type: I18n.t('news_service.mailheader_type'),
        **unsubscribe_links_for(user)
      )

      mail(to: user.fetch('email'), subject: translation.fetch('subject'))
    end
  end

  class << self
    def call(*)
      announcement(*).deliver_now
    end
  end

  private

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def email_resource_for(user)
    @email_resource ||=
      Xikolo.api(:account).value!
        .rel(:user).get({id: user.fetch('id')}).value!
        .rel(:emails).get.then(&:first)
  end
  # rubocop:enable all

  # Generate local (from announcements) and global
  # (from all emails) disable/unsubscribe links
  def unsubscribe_links_for(user)
    email = email_resource_for(user).value!
    email_hash = Digest::SHA256.hexdigest \
      [email.fetch('id'), user.fetch('id')].join

    global_link = Addressable::URI.parse \
      Xikolo.base_url.join('notification_user_settings/disable')
    global_link.query_values = {
      email: user.fetch('email'),
      hash: email_hash,
      key: 'global',
    }

    local_link = Addressable::URI.parse \
      Xikolo.base_url.join('notification_user_settings/disable')
    local_link.query_values = {
      email: user.fetch('email'),
      hash: email_hash,
      key: 'announcement',
    }

    {disable_link_global: global_link.to_s, disable_link_local: local_link.to_s}
  end

  # We let mailboxes know that we are sending emails in bulk,
  # to prevent them from sending back out-of-office emails and
  # similar automatically generated responses.
  def bulk_mail_headers
    headers['Precedence'] = 'bulk'
    headers['Auto-Submitted'] = 'auto-generated'
  end

  # If there's a URL provided to unsubscribe from these announcements,
  # add this URL to the appropriate mail headers so that
  # compliant mail clients can offer one-click unsubscription.
  def unsubscribe_header
    return if unsubscribe_link_header.blank?

    headers['List-Unsubscribe'] = "<#{unsubscribe_link_header}>"
  end

  def unsubscribe_link_header
    @payload.disable_link_local || @payload.disable_link_global
  end
end
end
