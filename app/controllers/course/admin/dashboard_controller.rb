# frozen_string_literal: true

module Course
  module Admin
    class DashboardController < Abstract::FrontendController
      include CourseContextHelper

      before_action :set_no_cache_headers

      inside_course

      def show
        authorize! 'course.dashboard.view'

        @course = the_course
        Acfs.run # wait for course context promises

        @age_distribution_table_rows = ::Admin::Statistics::AgeDistribution.call(course_id: @course.id)
        @age_distribution_table_headers = [
          t('admin.course_management.dashboard.age.table.age_group'),
          t('admin.course_management.dashboard.age.table.course_count'),
          t('admin.course_management.dashboard.age.table.course_share'),
          t('admin.course_management.dashboard.age.table.global_count'),
          t('admin.course_management.dashboard.age.table.global_share'),
        ]

        @client_usage_table_rows = ::Admin::Statistics::ClientUsage.call(
          course_id: @course.id,
          start_date: @course.start_date || @course.created_at,
          end_date: @course.end_date || Time.zone.today
        )
        @client_usage_table_headers = [
          t('admin.course_management.dashboard.client_usage.table.client_types'),
          t('admin.course_management.dashboard.client_usage.table.users'),
          t('admin.course_management.dashboard.client_usage.table.share'),
        ]
      end

      def hide_course_nav?
        true
      end

      private

      def auth_context
        the_course.context_id
      end

      # fix course receiving
      def request_course
        Xikolo::Course::Course.find(params[:id])
      end
    end
  end
end
