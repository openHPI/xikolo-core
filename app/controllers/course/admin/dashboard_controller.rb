# frozen_string_literal: true

require 'will_paginate/collection'

module Course
  module Admin
    class DashboardController < Abstract::FrontendController
      include CourseContextHelper

      inside_course

      def show
        authorize! 'course.dashboard.view'

        @course = the_course
        Acfs.run # wait for course context promises

        course_id = @course.id
        @course_kpi_cards = ::Admin::Statistics::Course::KpiCards.call(course_id:)
        kpi_cards = @course_kpi_cards || {}
        @kpi_enrollments_stats = kpi_cards[:enrollments] || {}
        @kpi_activity_stats = kpi_cards[:activity] || {}
        @kpi_certificates_stats = kpi_cards[:certificates] || {}
        @course_quiz_performance = {
          graded: ::Admin::Statistics::Course::TotalQuizPerformance.call(course_id:, type: :graded),
          selftest: ::Admin::Statistics::Course::TotalQuizPerformance.call(course_id:, type: :selftest),
        }

        @age_distribution_table_rows = ::Admin::Statistics::AgeDistribution.call(course_id:)
        @age_distribution_table_headers = [
          t('admin.course_management.dashboard.age.table.age_group'),
          t('admin.course_management.dashboard.age.table.global_count'),
          t('admin.course_management.dashboard.age.table.global_share'),
          t('admin.course_management.dashboard.age.table.course_count'),
          t('admin.course_management.dashboard.age.table.course_share'),
        ]
      end

      private

      def auth_context
        the_course.context_id
      end

      # fix course receiving
      def request_course
        course = CourseService::Course.by_identifier(params[:id]).take
        if course.nil?
          raise Status::NotFound
        end

        course
      end
    end
  end
end
