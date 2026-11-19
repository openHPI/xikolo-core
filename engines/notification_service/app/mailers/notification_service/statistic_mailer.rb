# frozen_string_literal: true

module NotificationService
class StatisticMailer < ApplicationMailer # rubocop:disable Layout/IndentationWidth
  include NotificationService::MailerHelper

  layout 'notification_service/foundation'

  def global_admin_statistics(receiver_email, admin_statistic)
    # Global stats
    @admin_statistic = admin_statistic

    # Data for email header
    @payload = Hashie::Mash.new
    subject = t('notification_service.statistic_mail.admin.subject', site: Xikolo.config.site_name, date: current_date)
    @payload.mailheader_type = t('notification_service.statistic_mail.admin.mailheader_type',
      site: Xikolo.config.site_name)
    @payload.mailheader_info = current_date

    mail to: receiver_email, subject:, template_name: 'global_admin_statistics'
  end

  private

  def current_date
    @current_date ||= DateTime.now.to_fs(:db)
  end
end
end
