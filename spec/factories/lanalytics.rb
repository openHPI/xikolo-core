# frozen_string_literal: true

FactoryBot.define do
  factory 'lanalytics:root', class: Hash do
    report_types_url { '/report_types' }
    report_jobs_url { '/report_jobs' }
    metric_url { '/metrics/{name}' }
    metrics_url { '/metrics' }

    initialize_with { attributes.as_json }
  end

  factory 'lanalytics:report_type', class: Hash do
    trait :course_report do
      type { 'course_report' }
      name { 'Course Report' }
      description { 'This report includes data about each enrollment of a course.' }
      scope do
        {
          type: 'select', name: 'task_scope', label: 'Select a course:', values: 'courses',
          options: {prompt: 'Please select...', disabled: '', required: true}
        }
      end
      options do
        [
          {type: 'checkbox', name: 'machine_headers', label: 'Better machine-readable headers (lowercase and underscored).'},
          {type: 'checkbox', name: 'de_pseudonymized', label: 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.'},
          {type: 'checkbox', name: 'include_access_groups', label: "Include data about the users' memberships in configured access groups."},
          {type: 'checkbox', name: 'include_profile', label: 'Include additional profile data. Sensitive data is omitted if pseudonymized.'},
          {type: 'checkbox', name: 'include_auth', label: 'Include certain configured authorization attributes of users (de-pseudonymization required).'},
          {type: 'checkbox', name: 'include_analytics_metrics', label: 'Include learning analytics metrics. This can significantly increase the time to create the report.'},
          {type: 'checkbox', name: 'include_all_quizzes', label: 'Include all quizzes.'},
          {type: 'text_field', name: 'zip_password', label: 'Optional password for the generated ZIP archive:', options: {placeholder: 'Password', input_size: 'large'}},
        ]
      end
    end

    trait :submission_report do
      type { 'submission_report' }
      name { 'Quiz Submissions Report' }
      description { 'This report includes data about each submission of a quiz.' }
      scope do
        {
          type: 'text_field', name: :task_scope, label: 'Enter a Quiz ID (the Content ID of the item):',
          options: {placeholder: 'Quiz ID', input_size: 'large', required: true}
        }
      end
      options do
        [
          {type: 'checkbox', name: :machine_headers, label: 'Better machine-readable headers (lowercase and underscored).'},
          {type: 'checkbox', name: :de_pseudonymized, label: 'De-pseudonymize report. Attention! Only use this option if the further processing of the data is in compliance with the data protection regulations of the platform.'},
          {type: 'text_field', name: 'zip_password', label: 'Optional password for the generated ZIP archive:', options: {placeholder: 'Password', input_size: 'large'}},
        ]
      end
    end

    trait :enrollment_statistics_report do
      type { 'enrollment_statistics_report' }
      name { 'Enrollment Statistics Report' }
      description { 'This report includes the total enrollments count and unique enrolled users count for a given timeframe.' }
      options do
        [
          {type: 'checkbox', name: :machine_headers, label: 'Better machine-readable headers (lowercase and underscored).'},
          {type: 'date_field', name: :first_date, options: {min: '2013-01-01', required: true}, label: 'First date:'},
          {type: 'date_field', name: :last_date, options: {min: '2013-01-01', required: true}, label: 'Last date:'},
          {type: 'radio_group', name: :window_unit, values: {days: 'Days', months: 'Months (the day input fields are ignored)'}, label: 'Unit of time window:'},
          {type: 'number_field', name: :window_size, options: {value: 1, min: 1, input_size: 'extra-small'}, label: 'Length of time window:'},
          {type: 'checkbox', name: :sliding_window, label: 'Sliding window instead of fixed interval.'},
          {type: 'checkbox', name: :include_all_classifiers, label: 'Include a filtered report for all defined course classifiers.'},
          {type: 'checkbox', name: :include_active_users, label: 'Include active users (experimental analytics metric).'},
          {type: 'text_field', name: 'zip_password', label: 'Optional password for the generated ZIP archive:', options: {placeholder: 'Password', input_size: 'large'}},
        ]
      end
    end

    trait :overall_course_summary_report do
      type { 'overall_course_summary_report' }
      name { 'Overall Course Summary Report' }
      description { 'This report includes data about each course of the platform.' }
      options do
        [
          {type: 'checkbox', name: 'machine_headers', label: 'Better machine-readable headers (lowercase and underscored).'},
          {type: 'checkbox', name: 'include_statistics', label: 'Include course statistics.'},
          {type: 'date_field', name: 'end_date', options: {min: '2013-01-01'}, label: 'End date:'},
          {type: 'text_field', name: 'zip_password', label: 'Optional password for the generated ZIP archive:', options: {placeholder: 'Password', input_size: 'large'}},
        ]
      end
    end

    initialize_with { attributes.as_json }
  end
end
