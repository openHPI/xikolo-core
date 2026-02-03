# frozen_string_literal: true

if defined? FactoryBot
  class FactoryBot::Syntax::Default::DSL
    def xikolo_uuid_sequence(name, args)
      service = args.fetch(:service).to_i
      resource = args.fetch(:resource).to_i
      sequence(name) {|i| format('81e01000-%d-4444-a%03d-0000000%05d', service, resource, i) }
    end
  end

  FactoryBot.define do
    xikolo_uuid_sequence(:user_id,     service: 3100, resource: 1)
    xikolo_uuid_sequence(:context_id,  service: 3100, resource: 2)
    xikolo_uuid_sequence(:group_id,    service: 3100, resource: 3)
    xikolo_uuid_sequence(:session_id,  service: 3100, resource: 4)

    xikolo_uuid_sequence(:course_id,   service: 3300, resource: 1)
    xikolo_uuid_sequence(:section_id,  service: 3300, resource: 2)
    xikolo_uuid_sequence(:item_id,     service: 3300, resource: 3)

    xikolo_uuid_sequence(:richtext_id, service: 3700, resource: 1)

    xikolo_uuid_sequence(:quiz_id,     service: 3800, resource: 1)
    xikolo_uuid_sequence(:question_id, service: 3800, resource: 2)

    xikolo_uuid_sequence(:file_id,     service: 4000, resource: 1)

    factory 'lanalytics:root', class: Hash do
      metric_url { '/metrics/{name}' }
      metrics_url { '/metrics' }
      report_jobs_url { '/report_jobs{?job_params,task_type,user_id,show_expired}' }
      report_job_url { '/report_jobs/{id}' }
      report_types_url { '/report_types' }
      course_statistics_url { '/course_statistics' }
      course_statistic_url { '/course_statistics/{id}' }
      system_info_url { '/system_info/{id}' }
      initialize_with { attributes.as_json }
    end
  end
end
