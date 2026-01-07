# frozen_string_literal: true

module NotificationService
class StatisticMailer < ApplicationMailer # rubocop:disable Layout/IndentationWidth
  include NotificationService::MailerHelper

  layout 'notification_service/foundation'

  def global_admin_statistics(receiver_email, admin_statistic)
    # Global stats
    @admin_statistic = admin_statistic
    @course_stats = admin_statistic.course_stats

    # Data for email header
    @payload = Hashie::Mash.new
    subject = t('notification_service.statistic_mail.admin.subject', site: Xikolo.config.site_name, date: current_date)
    @payload.mailheader_type = t('notification_service.statistic_mail.admin.mailheader_type',
      site: Xikolo.config.site_name)
    @payload.mailheader_info = current_date

    # Add attachments
    @enrollments = EnrollmentChart.new @course_stats
    attachments.inline['chart.png'] = @enrollments.to_png unless @enrollments.empty?

    mail to: receiver_email, subject:, template_name: 'global_admin_statistics'
  end

  def course_admin_statistics(receiver_obj, admin_statistic, course_stats)
    @receiver = receiver_obj

    I18n.with_locale(get_language(@receiver.fetch('language'))) do
      # Global stats
      @admin_statistic = admin_statistic
      @course_stats = course_stats

      # Data for email header
      @payload = Hashie::Mash.new
      subject = t('notification_service.statistic_mail.course_admin.subject', site: Xikolo.config.site_name,
        date: current_date)
      @payload.mailheader_type = t('notification_service.statistic_mail.course_admin.mailheader_type',
        site: Xikolo.config.site_name)
      @payload.mailheader_info = current_date

      # Add the enrollment chart image as attachment
      @enrollments = EnrollmentChart.new @course_stats
      attachments.inline['chart.png'] = @enrollments.to_png unless @enrollments.empty?

      mail to: @receiver.fetch('email'), subject:, template_name: 'course_admin_statistics'
    end
  end

  private

  def current_date
    @current_date ||= DateTime.now.to_fs(:db)
  end
end
end
