# frozen_string_literal: true

module NotificationService
class CourseStats # rubocop:disable Layout/IndentationWidth
  #
  # Exported from lanalytics course statistics presenter
  #
  FIELDS = [
    'id',
    'course_code',
    'course_id',
    'course_status',
    'start_date',
    'end_date',
    'hidden',
    'days_since_coursestart',
    'created_at',
    'updated_at',

    # enrollments
    'total_enrollments',
    'current_enrollments',
    'enrollments_per_day',
    'new_users',

    'enrollments_last_day',
    'enrollments_at_course_start',
    'enrollments_at_course_start_netto',
    'enrollments_at_course_middle',
    'enrollments_at_course_middle_netto',
    'enrollments_at_course_end',
    'enrollments_at_course_end_netto',

    'shows',
    'shows_at_middle',
    'shows_at_end',
    'no_shows',
    'no_shows_at_middle',
    'no_shows_at_end',

    # active users
    'active_users_last_day',
    'active_users_last_7days',

    # success
    'roa_count',
    'cop_count',
    'qc_count',
    'completion_rate',
    'consumption_rate',

    # pinboard
    'threads',
    'threads_last_day',
    'posts',
    'posts_last_day',

    # helpdesk
    'helpdesk_tickets',
    'helpdesk_tickets_last_day',

    # open badges
    'badge_issues',
    'badge_downloads',
    'badge_shares',
  ].freeze

  DATE_FIELDS = %w[
    start_date
    end_date
    created_at
    updated_at
  ].freeze

  attr_reader(*FIELDS, *DATE_FIELDS)

  def initialize(resource)
    FIELDS.each do |field|
      if DATE_FIELDS.include?(field) && resource[field].present?
        # Info: Lanalytics does *NOT* consistently return ISO 8601
        value = Time.zone.parse(resource[field])
      else
        value = resource[field]
      end

      instance_variable_set(:"@#{field}", value)
    end
  end

  class << self
    def verify(data)
      keys = data.keys.map(&:to_s)
      missing = FIELDS.difference(keys)
      if missing.any?
        raise ArgumentError.new("Missing fields: #{missing.join(',')}")
      end

      extra = keys.difference(FIELDS)
      if extra.any?
        raise ArgumentError.new("Extra fields: #{extra.join(',')}")
      end

      data
    end
  end
end
end
