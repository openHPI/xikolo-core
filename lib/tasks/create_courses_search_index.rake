# frozen_string_literal: true

namespace :search_index do
  desc <<-DOC.gsub(/\s+/, ' ')
    Create or update search index for all courses
  DOC
  task create: :environment do
    CourseService::Course.unscope(:order).in_batches do |courses|
      job_args = courses.ids.zip
      job_args.each do |course_id|
        CourseService::UpdateCourseSearchIndexJob.perform_later(course_id)
      end
      $stdout.print 'launched update of search index for courses'
      $stdout.print "\n"
      $stdout.flush
    end
  end
end
