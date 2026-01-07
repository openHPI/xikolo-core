# frozen_string_literal: true

namespace :unenroll do
  require 'logger'

  desc <<-DOC.gsub(/\s+/, ' ')
  Delete enrollments for internal courses (or a single course if COURSE_CODE is given as argument)
  DOC
  task internal_courses: :environment do
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @dry = ENV.fetch('DRY', nil)
    @course_code = ENV['COURSE_CODE'] if ENV['COURSE_CODE']

    init_msg = 'Checking enrollments for internal courses...'
    init_msg = "Checking enrollments for #{@course_code}" if @course_code
    init init_msg
    inform 'This is a DRY run...' if @dry

    affiliated_courses = []
    if @course_code
      affiliated_courses << CourseService::Course.find_by(course_code: @course_code,
        affiliated: true)
    else
      CourseService::Course.find_each do |course|
        if course.affiliated
          inform "Found affected course: #{course.course_code}"
          affiliated_courses << course
        end
      end
    end
    if affiliated_courses.empty?
      inform 'No internal courses found.'
      exit 0
    end

    affiliated_courses.each do |affiliated_course|
      inform "Checking for course #{affiliated_course.course_code}"
      affiliated_course.enrollments.each do |enrollment|
        user = account_api.rel(:user).get({id: enrollment.user_id}).value!
        if user['affiliated']
          inform "Enrollment ok: course #{affiliated_course.course_code}, " \
                 "user #{user['full_name']}, affiliated: #{user['affiliated']}"
        else
          inform 'Delete enrollment: ' \
                 "course #{affiliated_course.course_code}, " \
                 "user #{user['full_name']}, " \
                 "affiliated: #{user['affiliated']}"
          enrollment.delete unless @dry
        end
      end
    end
  end

  ######################################
  # #######helpers##helpers##############
  ######################################

  def init(procedure)
    @log = create_logger(procedure) unless @dry
    puts procedure
  end

  def create_logger(procedure)
    log = Logger.new($stdout)
    log.info('======== START ========')
    log.info(procedure)
    log
  end

  def inform(info)
    puts info
    @log.info(info) unless @dry
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
