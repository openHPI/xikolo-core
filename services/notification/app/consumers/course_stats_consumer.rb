# frozen_string_literal: true

class CourseStatsConsumer < Msgr::Consumer
  # We know that the course statistics are calculated daily.
  # Thus, we listen to this event and send the statistics email every time it occurs.
  def send_daily_mails
    prepare_global_admin_stats!
    prepare_course_admin_stats!

    # First, we generate the mails, and then we send them all at once.
    # This prevents failures in generating course admin mails triggering a
    # retry, which then sends the (already sent) global admin mail again.
    mails.each(&:deliver_now!)
  end

  private

  def prepare_global_admin_stats!
    return if Xikolo.config.statistics_email_recipients.blank?

    mails << StatisticMailer.global_admin_statistics(
      Xikolo.config.statistics_email_recipients,
      admin_statistic
    )
  end

  def prepare_course_admin_stats!
    # Every course admin gets exactly one additional email (unless disabled) with information about
    # all the courses where they are admins.
    course_admins_who_want_mails.each do |admin, course_stats|
      mails << StatisticMailer.course_admin_statistics(
        admin,
        admin_statistic,
        course_stats
      )
    end
  end

  def mails
    @mails ||= []
  end

  def admin_statistic
    @admin_statistic ||= AdminStatistic.new
  end

  def course_admins_who_want_mails
    empty_hash = Hash.new {|hash, key| hash[key] = [] }
    course_admin_courses.each_with_object(empty_hash) do |course, courses_by_admins|
      course_admins(course).each do |admin|
        courses_by_admins[admin] << course
      end
    end.reject do |admin|
      disabled_notifications? admin.rel(:preferences).get.value!['properties']
    end
  end

  EMAIL_NOTIFICATION_TYPES = %w[notification.email.global notification.email.stats].freeze
  private_constant :EMAIL_NOTIFICATION_TYPES

  def disabled_notifications?(preferences)
    # Make sure the user has not disabled these notifications (or all types)
    EMAIL_NOTIFICATION_TYPES.any? do |pref|
      preferences.fetch(pref, 'true') == 'false'
    end
  end

  # Select all courses that are still running, are upcoming or have finished recently
  def course_admin_courses
    # TODO: Can this be changed to `reject` and a simpler condition?
    admin_statistic.course_stats.select do |stat|
      current = stat.start_date && stat.start_date < DateTime.now && stat.course_status == 'active'
      upcoming = stat.start_date && stat.start_date > DateTime.now
      recent = stat.end_date && stat.end_date > DateTime.now - 14.days && stat.course_status == 'archive'

      current || upcoming || recent
    end
  end

  def course_admins(course)
    account_service.value!.rel(:group).get(
      id: "course.#{course.course_code}.admins"
    ).value!.rel(:members).get.value!
  end

  def account_service
    @account_service ||= Xikolo.api(:account)
  end
end
