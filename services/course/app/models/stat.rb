# frozen_string_literal: true

# rubocop:disable Layout/LineLength
class Stat
  extend ActiveModel::Naming

  attr_reader :course_id,
    :enrollments, :enrollments_netto, :enrollments_by_day, :enrollments_last_day,
    :enrollments_at_start, :enrollments_at_start_netto,
    :enrollments_at_middle, :enrollments_at_middle_netto,
    :enrollments_at_end, :enrollments_at_end_netto,
    :shows, :shows_at_start, :shows_at_middle, :shows_at_end,
    :no_shows, :no_shows_at_start, :no_shows_at_middle, :no_shows_at_end,
    :percentile_created_at_days, :certificates_count, :quantile_count, :platform_enrollments,
    :platform_current_enrollments, :platform_last_day_enrollments, :platform_last_day_unique_enrollments,
    :platform_enrollment_delta_sum, :unenrollments, :overall_progress,
    :platform_last_7days_enrollments, :new_users, :total_certificates, :platform_custom_completed, :courses,
    :proctorings, :reactivations

  def initialize(attrs)
    @course_id = attrs['course_id']

    case attrs['key']
      when 'enrollments'
        enrollment_stats
      when 'enrollments_by_day'
        enrollments_by_day_stats
      when 'overall_progress'
        overall_progress_stats
      when 'percentile_created_at_days'
        # the days on which a course statistic (percentile) has been created by the teaching team
        percentile_created_at_days_stats
      when 'global'
        # global stats for current enrollment
        global_stats
      when 'shows_and_no_shows'
        shows_and_no_shows_stats
      when 'extended'
        extended_stats
      when 'bookings'
        booking_stats
    end
  end

  private

  def enrollment_stats
    enrollment_delta = course.enrollment_delta

    @enrollments = course.enrollments.count + enrollment_delta
    @enrollments_netto = course.enrollments.active.count + enrollment_delta
    @enrollments_last_day = course.enrollments.created_last_day.count

    if course.start_date&.past?
      enrollments = course.enrollments.created_at_latest(course.start_date)
      @enrollments_at_start = enrollments.count + enrollment_delta
      @enrollments_at_start_netto = enrollments.active.count + enrollment_delta
    end

    if course.middle_of_course&.past?
      enrollments = course.enrollments.created_at_latest(course.middle_of_course)
      @enrollments_at_middle = enrollments.count + enrollment_delta
      @enrollments_at_middle_netto = enrollments.active.count + enrollment_delta
    end

    if course.end_date&.past?
      enrollments = course.enrollments.created_at_latest(course.end_date)
      @enrollments_at_end = enrollments.count + enrollment_delta
      @enrollments_at_end_netto = enrollments.active.count + enrollment_delta
    end
  end

  def overall_progress_stats
    overall_progress = []
    course.sections.each do |section|
      item_ids = Item.all_available.where(section_id: section.id).pluck(:id)
      section_result = {}
      section_result['title'] = section.title
      section_result['id'] = section.id
      section_result['users_visited'] = Visit.where(item_id: item_ids).group_by(&:user_id).count
      section_result['users_submitted'] = Result.where(item_id: item_ids).group_by(&:user_id).count
      section_result['avg_points'] = Result.where(item_id: item_ids).group_by(&:user_id).sum(:dpoints)
      overall_progress << section_result
    end
    @overall_progress = overall_progress
  end

  def enrollments_by_day_stats
    # we have to unscope here, because the default scope adds a sorting that conflicts with the grouping
    @enrollments_by_day = course.enrollments.unscope(:order).group_by_day(:created_at).count
  end

  def percentile_created_at_days_stats
    @percentile_created_at_days = FixedLearningEvaluation.select(:user_id).where(course_id: @course_id).group_by_day(:created_at).count
    @quantile_count = course.enrollments.where.not(quantile: nil).count
  end

  def global_stats
    @platform_current_enrollments = Enrollment.active.count
    @platform_enrollments = Enrollment.count
    @platform_custom_completed = Enrollment.where(completed: true).count
    @platform_last_day_enrollments = Enrollment.created_last_day.count
    @platform_last_day_unique_enrollments = Enrollment.created_last_day.select('DISTINCT user_id').count
    @platform_last_7days_enrollments = Enrollment.created_last_7days.count
    @platform_enrollment_delta_sum = Course.sum(:enrollment_delta)
    @quantile_count = Enrollment.where.not(quantile: nil).count
    @total_certificates = @quantile_count # deprecated
    @unenrollments = Enrollment.where(deleted: true).count
    @courses = Course.published.not_deleted.where.not(external_course_url: nil).where(hidden: false).count
  end

  def extended_stats
    enrollment_stats

    shows_and_no_shows_stats

    @quantile_count = course.enrollments.where.not(quantile: nil).count
    @certificates_count = @quantile_count # deprecated

    @new_users = course.enrollments.where('not exists(select id from enrollments inn where inn.user_id = enrollments.user_id AND inn.created_at < enrollments.created_at)').count
  end

  def shows_and_no_shows_stats
    @shows, @no_shows = shows_and_no_shows_at(nil, for_course: course)

    if course.start_date&.past?
      @shows_at_start, @no_shows_at_start = shows_and_no_shows_at(course.start_date, for_course: course)
    end

    if course.middle_of_course&.past?
      @shows_at_middle, @no_shows_at_middle = shows_and_no_shows_at(course.middle_of_course, for_course: course)
    end

    if course.end_date&.past?
      @shows_at_end, @no_shows_at_end = shows_and_no_shows_at(course.end_date, for_course: course)
    end
  end

  def shows_and_no_shows_at(date, for_course: course)
    shows = Visit.where(item_id: for_course.items.unscope(:order).select(:id))
    shows = shows.where(user_id: for_course.enrollments.unscope(:order).select(:user_id))
    shows = shows.where(created_at: ..date) if date
    shows = shows.distinct.count(:user_id) + for_course.enrollment_delta

    no_shows = for_course.enrollments
    no_shows = no_shows.created_at_latest(date) if date
    no_shows = no_shows.count - shows + for_course.enrollment_delta

    [shows, no_shows]
  end

  def booking_stats
    @proctorings = course.enrollments.where(proctored: true).count
    @reactivations = course.enrollments.reactivated.count
  end

  def course
    @course ||= Course.find(@course_id)
  end
end
# rubocop:enable Layout/LineLength
