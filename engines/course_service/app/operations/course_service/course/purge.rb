# frozen_string_literal: true

module CourseService
  class Course::Purge < ApplicationOperation
    attr_reader :course

    def initialize(course)
      super()
      @course = course
    end

    def call
      return course unless course.deleted?

      ActiveRecord::Base.transaction do
        destroy_enrollments!
        destroy_course_progresses!
        destroy_course_subscriptions!
        destroy_dates!
        destroy_content_tests!
        destroy_sections!
      end

      ActiveRecord::Base.transaction do
        course.destroy!
      end

      course
    end

    private

    def destroy_enrollments!
      course.enrollments.destroy_all
    end

    def destroy_course_progresses!
      CourseService::CourseProgress.where(course_id: course.id).delete_all
    end

    def destroy_course_subscriptions!
      PinboardService::CourseSubscription.where(course_id: course.id).delete_all
    end

    def destroy_dates!
      CourseService::NextDate.where(course_id: course.id).delete_all
    end

    def destroy_sections!
      course.sections.find_each do |section|
        section.items.find_each do |item|
          destroy_item!(item)
        end
        section.destroy!
      end
    end

    def destroy_item!(item)
      item.node&.delete
      item.results.delete_all
      item.visits.delete_all
      content = item.content
      item.content_id = nil
      item.delete
      content&.destroy!
    end

    def destroy_content_tests!
      course.content_tests.find_each do |content_test|
        destroy_content_test_groups!(content_test)
        content_test.forks.find_each(&:destroy!)
        content_test.destroy!
      end
    end

    def destroy_content_test_groups!(content_test)
      content_test.groups.each do |name|
        account_api.rel(:group).delete(
          {id: "course.#{original_course_code}.content_test.#{content_test.identifier}.#{name}"}
        )
      end.each(&:value!)
    rescue Restify::ServerError, Restify::ClientError => e
      Sentry.capture_exception(e)
    end

    def original_course_code
      @original_course_code ||= course.course_code.rpartition('-deleted-').first
    end

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
