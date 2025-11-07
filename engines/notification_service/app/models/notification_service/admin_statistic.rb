# frozen_string_literal: true

module NotificationService
class AdminStatistic # rubocop:disable Layout/IndentationWidth
  attr_reader :course_stats

  def initialize
    @platform_course_stats_promise = course_api.rel(:stats).get({key: 'global'})
    @platform_user_stats_promise = account_api.rel(:statistics).get
    @platform_certificate_stats_promise = lanalytics_api.rel(:metric).get({name: 'certificates'})

    # Load all course stats
    # We do not parallelize these requests, as that tends to overload the lanalytics
    # service and result in timeouts (many courses, many requests)
    @course_stats = courses.filter_map do |course|
      stats = lanalytics_api.rel(:course_statistic).get({id: course['id']}).value!
      CourseStats.new(stats)
    rescue Restify::NotFound
      # Course stats for newly published courses may not have been calculated yet.
      nil
    end
  end

  def course(id)
    courses.find {|c| c['id'] == id }
  end

  def platform_course_stats
    @platform_course_stats_promise.value!
  end

  def platform_user_stats
    @platform_user_stats_promise.value!
  end

  def platform_certificate_stats
    @platform_certificate_stats_promise.value!
  end

  HelpdeskStats = Struct.new(:ticket_count, :ticket_count_last_day)
  def helpdesk
    HelpdeskStats.new(
      Duplicated::HelpdeskTicket.count,
      Duplicated::HelpdeskTicket.created_last_day.count
    )
  end

  def platform_enrollments
    platform_course_stats['platform_enrollments'] +
      platform_course_stats['platform_enrollment_delta_sum'] +
      Xikolo.config.global_enrollment_delta
  end

  def platform_user
    platform_user_stats['confirmed_users'] + Xikolo.config.global_users_delta
  end

  private

  def courses
    @courses ||= begin
      courses = []
      Xikolo.paginate(
        course_api.rel(:courses).get({groups: 'any'})
      ) do |course|
        next if course['status'] == 'preparation' || course['external_course_url'].present?

        courses.append course
      end
      courses
    end
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def lanalytics_api
    @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
  end
end
end
