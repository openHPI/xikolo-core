# frozen_string_literal: true

require 'tracking_mail_interceptor'

class NotificationMailer < ApplicationMailer
  include MailerHelper

  layout :layout_name

  after_action :bulk_mail_headers
  after_action :unsubscribe_header
  after_action :track_links

  def notification(receiver, key, payload)
    @receiver = receiver

    I18n.with_locale get_language(@receiver.language) do
      @payload = Hashie::Mash.new payload
      @key = key

      @payload.mailheader_type = t("notifications.#{key}.mailheader_type", **payload.symbolize_keys, default: nil)
      @payload.mailheader_info = t("notifications.#{key}.mailheader_info", **payload.symbolize_keys, default: nil)

      mail(
        to: @receiver.email,
        subject: subject_for(key, payload),
        template_path: 'notifications',
        template_name: key.tr('.', '/')
      )
    end
  end

  private

  MAILS_WITH_OLD_LAYOUT = %w[
    peer_assessments.conflict.new.accused_student
    peer_assessments.conflict.new.reporter
    peer_assessments.conflict.new.staff
    peer_assessments.conflict.resolved.accused_student
    peer_assessments.conflict.resolved.reporter
    pinboard.blocked_item
    report.new_report
  ].freeze
  private_constant :MAILS_WITH_OLD_LAYOUT

  def layout_name
    MAILS_WITH_OLD_LAYOUT.include?(@key) ? 'old' : 'foundation'
  end

  # For the following notification types, we let mailboxes know that we are
  # sending emails in bulk, to prevent them from sending back out-of-office
  # emails and similar automatically generated responses.
  BULK_MAIL_TYPES = ['news.announcement'].freeze
  private_constant :BULK_MAIL_TYPES

  def bulk_mail_headers
    return unless BULK_MAIL_TYPES.include? @key

    headers['Precedence'] = 'bulk'
    headers['Auto-Submitted'] = 'auto-generated'
  end

  # If we are provided a URL where this type of notification's (or all emails)
  # can be unsubscribed, add this URL to the appropriate mail headers so that
  # compliant mail clients can offer one-click unsubscription.
  def unsubscribe_header
    return unless disable_link

    headers['List-Unsubscribe'] = "<#{disable_link}>"
  end

  # Rewrite URLs so that we can track email views and clicks on links.
  def track_links
    return unless Xikolo.config.track_mails

    # HACK: Call the old interceptor which takes care of rewriting here. In the
    # short-term future, this will be rewritten to a properly testable class.
    #
    # This will be used to rewrite the payload content, instead of reaching
    # into the depths of the assembled mail message object (@_message is
    # a private ActionMailer variable, it should not be touched).
    TrackingMailInterceptor.delivering_email(
      @_message,
      {
        'tracking_user' => UUID4(@receiver.id).to_str(format: :base62),
        'tracking_type' => @payload['tracking_type'],
        'tracking_campaign' => @payload['tracking_campaign'],
        'tracking_id' => @payload['tracking_id'] && UUID4(@payload['tracking_id']).to_str(format: :base62),
        'tracking_course_id' => @payload['tracking_course_id'],
      }.compact
    )
  end

  def disable_link
    @payload.disable_link_local || @payload.disable_link_global
  end

  def subject_for(key, payload)
    if payload.key?('subject')
      subject = payload.fetch 'subject'
      if subject.is_a?(Hash)
        locale_string_from subject
      else
        subject.to_s
      end
    else
      # title can be a multilingual hash
      I18n.t("notifications.#{key}.subject", **payload.symbolize_keys)
    end
  end
end
