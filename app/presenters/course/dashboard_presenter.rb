# frozen_string_literal: true

class Course::DashboardPresenter
  class << self
    def enrollment_stats_data_transformer
      [
        [
          'total_enrollments',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.total_enrollments'),
        ],
        [
          'current_enrollments',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.current_enrollments'),
        ],
        [
          'enrollments_last_day',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.enrollments_last_day'),
        ],
        [
          'active_users_last_day',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.active_users_last_day'),
        ],
        [
          'active_users_last_7days',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.active_users_last_7days'),
        ],
        [
          'new_users',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.new_users'),
        ],
        [
          'no_shows',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.enrollments.no_shows'),
        ],
      ].map do |dimension|
        {
          x: {
            type: 'collect',
            sourceKey: 'timestamp',
          },
          y: {
            type: 'collect',
            sourceKey: dimension[0],
          },
          name: {
            type: 'constant',
            value: dimension[1],
          },
        }
      end.to_json
    end

    def forum_stats_data_transformer
      [
        [
          'posts',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.forum.posts'),
        ],
        [
          'threads',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.forum.topics'),
        ],
        [
          'helpdesk_tickets',
          I18n.t(:'admin.course_management.dashboard.stats_over_time.forum.helpdesk_tickets'),
        ],
      ].map do |dimension|
        {
          x: {
            type: 'collect',
            sourceKey: 'timestamp',
          },
          y: {
            type: 'collect',
            sourceKey: dimension[0],
          },
          name: {
            type: 'constant',
            value: dimension[1],
          },
        }
      end.to_json
    end

    def historic_v_lines(course)
      v_lines = []

      if course.start_date
        start_date = Date.parse(course.start_date.to_s)
        if start_date.past?
          v_lines.push(start_date.to_s)
        end
      end

      if course.end_date
        end_date = Date.parse(course.end_date.to_s)
        if end_date.past?
          v_lines.push(end_date.to_s)
        end
      end

      v_lines
    end

    def date_labels(course)
      if course.start_date && course.end_date
        start_date = Date.parse(course.start_date.to_s)
        end_date = Date.parse(course.end_date.to_s)
        if end_date.past?
          return I18n.t(
            :'admin.course_management.dashboard.stats_over_time.start_and_end_date',
            start_date: I18n.l(start_date, format: :short),
            end_date: I18n.l(end_date, format: :short)
          )
        end
      end

      if course.start_date
        start_date = Date.parse(course.start_date.to_s)
        if start_date.past?
          I18n.t(
            :'admin.course_management.dashboard.stats_over_time.start_date',
            start_date: I18n.l(start_date, format: :short)
          )
        end
      end
    end
  end
end
