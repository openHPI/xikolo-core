# frozen_string_literal: true

require 'spec_helper'

describe 'OpenHPI: Daily Statistic Mail' do
  subject do
    Msgr.publish({}, to: 'xikolo.lanalytics.course_stats.calculate')
    Msgr::TestPool.run
  end

  let(:course_id) { '00000001-3300-4444-9999-000000000006' }

  before do
    Msgr.client.start

    # Account service stubs
    Stub.service(:account, build(:'account:root'))
    Stub.request(
      :account, :get, '/groups/course.futcode.admins'
    ).to_return Stub.json({
      name: 'course.futcode.admins',
      description: 'Course Admins of course futcode',
      members_url: 'http://localhost:3000/account_service/groups/course.futcode.admins/members',
    })
    Stub.request(
      :account, :get, '/groups/course.futcode.admins/members'
    ).to_return Stub.json([
      {
        id: '00000001-3100-4444-9999-000000000003',
        full_name: 'Tom T. Teacher',
        language: 'en',
        email: 'tom@openhpi.de',
        preferences_url: 'http://localhost:3000/account_service/users/00000001-3100-4444-9999-000000000003/preferences',
      },
    ])
    Stub.request(
      :account, :get, '/users/00000001-3100-4444-9999-000000000003/preferences'
    ).to_return Stub.json({
      user_id: '00000001-3100-4444-9999-000000000003',
      properties: {'notification.email.stats' => 'true', 'notification.email.global' => 'true'},
    })
    Stub.request(
      :account, :get, '/statistic'
    ).to_return Stub.json({
      confirmed_users: 100,
      confirmed_users_last_day: 10,
    })

    # Course service stubs
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/courses',
      query: {groups: 'any'}
    ).to_return Stub.json([
      {id: course_id, course_code: 'futcode', title: 'Software Profiling Future', start_date: DateTime.now + 4.days, status: 'active'},
    ])
    Stub.request(
      :course, :get, '/stats',
      query: {key: 'global'}
    ).to_return Stub.json({
      platform_enrollments: 300,
      platform_last_day_enrollments: 42,
      platform_enrollment_delta_sum: 22,
    })

    # Lanalytics stubs
    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(
      :learnanalytics, :get, "/course_statistics/#{course_id}"
    ).to_return Stub.json({
      id: '00d6833d-d75c-4f64-813f-5d312bd7e686',
      course_code: 'futcode',
      course_id:,
      course_status: 'active',
      total_enrollments: 0,
      no_shows: 0,
      no_shows_at_middle: 0,
      no_shows_at_end: 0,
      shows: 0,
      shows_at_middle: 0,
      shows_at_end: 0,
      current_enrollments: 0,
      enrollments_last_day: 0,
      enrollments_at_course_start: 0,
      enrollments_at_course_start_netto: 0,
      enrollments_at_course_middle: 0,
      enrollments_at_course_middle_netto: 0,
      enrollments_at_course_end: 0,
      enrollments_at_course_end_netto: 0,
      posts: 0,
      posts_last_day: 0,
      threads: 0,
      threads_last_day: 0,
      roa_count: 0,
      helpdesk_tickets: 0,
      helpdesk_tickets_last_day: 0,
      start_date: 4.days.from_now,
      end_date: 12.days.from_now,
      new_users: 0,
      created_at: '2016-09-14T09:11:53.781Z',
      updated_at: '2016-09-14T11:29:57.596Z',
      completion_rate: 0.0,
      consumption_rate: 0.0,
      enrollments_per_day: [0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      hidden: false,
    })
    Stub.request(
      :learnanalytics, :get, '/metrics/certificates'
    ).to_return Stub.json({
      record_of_achievement: 0,
      confirmation_of_participation: 0,
      qualified_certificate: 0,
    })

    Stub.service(:pinboard, build(:'pinboard:root'))

    # Pinboard stubs
    Stub.request(
      :pinboard, :get, '/statistic'
    ).to_return Stub.json({
      questions: 500,
      questions_last_day: 50,
    })
  end

  context 'global statistic' do
    let(:mail) { subject; ActionMailer::Base.deliveries.first }

    before do
      Xikolo.config.statistics_email_recipients = ['admins@the-platform.org']
    end

    it 'includes the openHPI footer' do
      expect(conv_str(mail.html_part)).to include 'Geschäftsführung: Prof. Dr. Tobias Friedrich, Dr. Henrik Haenecke'
    end
  end
end
