# frozen_string_literal: true

namespace :stats do
  desc <<-DOC.gsub(/\s+/, ' ')
  Get some no show stats
  DOC
  # rubocop:disable Layout/LineLength
  task no_shows: :environment do
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @dry = ENV.fetch('DRY', nil)
    $stdout.print "course_code,enrollments,enrollments_during_active_course,no_shows,no_shows_after_7days,no_shhows_after_48hours,no_shows_after_24hours  \n"
    CourseService::Course.where.not(start_date: nil).where.not(end_date: nil).find_each do |course|
      shows = CourseService::Visit.select('DISTINCT user_id').where { item_id.in(course.items.reorder(nil).select(:id)) }.count
      shows_24 = CourseService::Visit.select('DISTINCT user_id').where { item_id.in(course.items.reorder(nil).select(:id)) }.where(created_at: ...course.end_date).where(['created_at > ?', course.start_date + 1.day]).count
      shows_48 = CourseService::Visit.select('DISTINCT user_id').where { item_id.in(course.items.reorder(nil).select(:id)) }.where(created_at: ...course.end_date).where(['created_at > ?', course.start_date + 2.days]).count
      shows_week = CourseService::Visit.select('DISTINCT user_id').where { item_id.in(course.items.reorder(nil).select(:id)) }.where(created_at: ...course.end_date).where(['created_at > ?', course.start_date + 7.days]).count
      enrollments = CourseService::Enrollment.where(course_id: course.id).count
      active_enrollments = CourseService::Enrollment.where(course_id: course.id).where(created_at: ...course.end_date).count
      $stdout.print "#{course.course_code},#{enrollments},#{active_enrollments},#{enrollments - shows},#{enrollments - shows_week},#{enrollments - shows_48},#{enrollments - shows_24}\n"
    end
    return
  end
  # rubocop:enable all
end
