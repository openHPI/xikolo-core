# frozen_string_literal: true

module Course
  module Admin
    module DashboardHelper
      def kpi_enrollments_metrics(enrollments_stats)
        stats = enrollments_stats || {}
        metrics = []

        if stats[:total]
          metrics << {
            counter: number_with_delimiter(stats[:total]),
            title: t('admin.course_management.dashboard.kpis.enrollments.total'),
          }
        end
        if stats[:last_day]
          metrics << {
            counter: "+#{number_with_delimiter(stats[:last_day])}",
            title: t('admin.course_management.dashboard.kpis.enrollments.last_day'),
          }
        end
        if stats[:at_start]
          metrics << {
            counter: number_with_delimiter(stats[:at_start]),
            title: t('admin.course_management.dashboard.kpis.enrollments.at_start'),
            quota_text: stats[:at_start_netto] && "#{number_with_delimiter(stats[:at_start_netto])}
             #{t('admin.course_management.dashboard.kpis.enrollments.non_deleted')}",
          }
        end
        if stats[:at_middle]
          metrics << {
            counter: number_with_delimiter(stats[:at_middle]),
            title: t('admin.course_management.dashboard.kpis.enrollments.at_middle'),
            quota_text: stats[:at_middle_netto] && "#{number_with_delimiter(stats[:at_middle_netto])}
             #{t('admin.course_management.dashboard.kpis.enrollments.non_deleted')}",
          }
        end
        if stats[:at_end]
          metrics << {
            counter: number_with_delimiter(stats[:at_end]),
            title: t('admin.course_management.dashboard.kpis.enrollments.at_end'),
            quota_text: stats[:at_end_netto] && "#{number_with_delimiter(stats[:at_end_netto])}
             #{t('admin.course_management.dashboard.kpis.enrollments.non_deleted')}",
          }
        end

        metrics
      end

      def kpi_activity_metrics(activity_stats)
        stats = activity_stats || {}
        metrics = []

        if stats[:shows]
          metrics << {
            counter: number_with_delimiter(stats[:shows]),
            title: t('admin.course_management.dashboard.kpis.activity.shows'),
            quota: stats[:show_quota].present? ? "#{stats[:show_quota]}%" : nil,
            quota_text: t('admin.course_management.dashboard.kpis.activity.show_rate_explanation'),
          }
        end
        if stats[:shows_at_middle]
          metrics << {
            counter: number_with_delimiter(stats[:shows_at_middle]),
            title: t('admin.course_management.dashboard.kpis.activity.shows_at_middle'),
            quota: stats[:show_quota_at_middle].present? ? "#{stats[:show_quota_at_middle]}%" : nil,
            quota_text: t('admin.course_management.dashboard.kpis.activity.shows_at_middle_rate_explanation'),
          }
        end
        if stats[:shows_at_end]
          metrics << {
            counter: number_with_delimiter(stats[:shows_at_end]),
            title: t('admin.course_management.dashboard.kpis.activity.shows_at_end'),
            quota: stats[:show_quota_at_end].present? ? "#{stats[:show_quota_at_end]}%" : nil,
            quota_text: t('admin.course_management.dashboard.kpis.activity.shows_at_end_rate_explanation'),
          }
        end

        metrics
      end

      def kpi_certificates_metrics(certificates_stats)
        stats = certificates_stats || {}
        metrics = []

        if stats[:roa_count]
          metrics << {
            counter: number_with_delimiter(stats[:roa_count]),
            title: t('admin.course_management.dashboard.kpis.certificates.roa'),
            quota: stats[:completion_rate].present? ? "#{stats[:completion_rate]}%" : nil,
            quota_text: t('admin.course_management.dashboard.kpis.certificates.completion_rate_explanation'),
          }
        end
        if stats[:cop_count]
          metrics << {
            counter: number_with_delimiter(stats[:cop_count]),
            title: t('admin.course_management.dashboard.kpis.certificates.cop'),
            quota: stats[:consumption_rate_current].present? ? "#{stats[:consumption_rate_current]}%" : nil,
            quota_text: t('admin.course_management.dashboard.kpis.certificates.consumption_rate_current_explanation'),
          }
        end
        if stats[:qc_count]
          metrics << {
            counter: number_with_delimiter(stats[:qc_count]),
            title: t('admin.course_management.dashboard.kpis.certificates.qc'),
          }
        end

        metrics
      end
    end
  end
end
