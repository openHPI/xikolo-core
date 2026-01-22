# frozen_string_literal: true

require 'will_paginate/collection'

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

        course_id = @course.id
        @course_kpi_cards = ::Admin::Statistics::Course::KpiCards.call(course_id:)
        kpi_cards = @course_kpi_cards || {}
        @kpi_enrollments_stats = kpi_cards[:enrollments] || {}
        @kpi_activity_stats = kpi_cards[:activity] || {}
        @kpi_certificates_stats = kpi_cards[:certificates] || {}
        @course_item_visits = ::Admin::Statistics::Course::ItemVisits.call(course_id:)
        @course_video_plays = ::Admin::Statistics::Course::VideoPlays.call(course_id:)
        @course_quiz_performance = {
          graded: ::Admin::Statistics::Course::TotalQuizPerformance.call(course_id:, type: :graded),
          selftest: ::Admin::Statistics::Course::TotalQuizPerformance.call(course_id:, type: :selftest),
        }
        @course_forum_statistics = if @course.pinboard_enabled
                                     ::Admin::Statistics::Course::Forum.call(course_id:)
                                   end

        @age_distribution_table_rows = ::Admin::Statistics::AgeDistribution.call(course_id:)
        @age_distribution_table_headers = [
          t('admin.course_management.dashboard.age.table.age_group'),
          t('admin.course_management.dashboard.age.table.global_count'),
          t('admin.course_management.dashboard.age.table.global_share'),
          t('admin.course_management.dashboard.age.table.course_count'),
          t('admin.course_management.dashboard.age.table.course_share'),
        ]

        @client_usage_table_rows = ::Admin::Statistics::ClientUsage.call(
          course_id:,
          start_date: @course.start_date || @course.created_at,
          end_date: @course.end_date || Time.zone.today
        )
        @client_usage_table_headers = [
          t('admin.course_management.dashboard.client_usage.table.client_types'),
          t('admin.course_management.dashboard.client_usage.table.users'),
          t('admin.course_management.dashboard.client_usage.table.share'),
        ]

        historic_rows = ::Admin::Statistics::HistoricData.call(course_id:).reverse
        historic_page = params[:historic_page].to_i
        historic_page = 1 if historic_page < 1
        per_page = 10

        @historic_data_pagination = WillPaginate::Collection.create(
          historic_page,
          per_page,
          historic_rows.size
        ) do |pager|
          offset = (historic_page - 1) * per_page
          pager.replace(historic_rows.slice(offset, per_page) || [])
        end

        @historic_data_table_rows = @historic_data_pagination
        @historic_data_table_headers = [
          t('admin.course_management.dashboard.historic_data.table.date'),
          t('admin.course_management.dashboard.historic_data.table.enrollments'),
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
