# frozen_string_literal: true

require 'spec_helper'

describe 'Daily Statistic Mails', type: :feature do
  subject do
    Msgr.publish({}, to: 'xikolo.lanalytics.course_stats.calculate')
    Msgr::TestPool.run
  end

  let(:course_id1) { '00000001-3300-4444-9999-000000000006' }
  let(:course_id2) { '00000001-3300-4444-9999-000000000007' }
  let(:course_id3) { '00000001-3300-4444-9999-000000000008' }

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
        email: 'tom@example.com',
        preferences_url: 'http://localhost:3000/account_service/users/00000001-3100-4444-9999-000000000003/preferences',
      },
    ])

    Stub.request(
      :account, :get, '/groups/course.aff.admins'
    ).to_return Stub.json({
      name: 'course.aff.admins',
      description: 'Course Admins of course aff',
      members_url: 'http://localhost:3000/account_service/groups/course.aff.admins/members',
    })

    Stub.request(
      :account, :get, '/groups/course.aff.admins/members'
    ).to_return Stub.json([
      {
        id: '00000001-3100-4444-9999-000000000003',
        full_name: 'Tom T. Teacher',
        language: 'en',
        email: 'tom@example.com',
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
      {id: course_id1, course_code: 'futcode', title: 'Software Profiling Future', start_date: DateTime.now + 4.days, status: 'active'},
      {id: course_id2, title: 'Course in Preparation', status: 'preparation'},
      {id: course_id3, course_code: 'aff', title: 'Company Course', affiliated: true, status: 'active', start_date: DateTime.now - 4.days},
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
      :learnanalytics, :get, "/course_statistics/#{course_id1}"
    ).to_return Stub.json(NotificationService::CourseStats.verify({
      id: '00d6833d-d75c-4f64-813f-5d312bd7e686',
      course_code: 'futcode',
      course_id: course_id1,
      course_status: 'active',
      start_date: 4.days.from_now,
      end_date: 12.days.from_now,
      created_at: '2016-09-14T09:11:53.781Z',
      updated_at: '2016-09-14T11:29:57.596Z',

      active_users_last_7days: nil,
      active_users_last_day: nil,
      badge_downloads: nil,
      badge_issues: nil,
      badge_shares: nil,
      completion_rate: 0.0,
      consumption_rate: 0.0,
      cop_count: nil, qc_count: nil,
      current_enrollments: 0,
      days_since_coursestart: 4,
      enrollments_at_course_end_netto: 0,
      enrollments_at_course_end: 0,
      enrollments_at_course_middle_netto: 0,
      enrollments_at_course_middle: 0,
      enrollments_at_course_start_netto: 0,
      enrollments_at_course_start: 0,
      enrollments_last_day: 0,
      enrollments_per_day: [0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      helpdesk_tickets_last_day: 0,
      helpdesk_tickets: 0,
      hidden: false,
      new_users: 0,
      no_shows_at_end: 0,
      no_shows_at_middle: 0,
      no_shows: 0,
      posts_last_day: 0,
      posts: 0,
      roa_count: 0,
      shows_at_end: 0,
      shows_at_middle: 0,
      shows: 0,
      threads_last_day: 0,
      threads: 0,
      total_enrollments: 0
    }))

    Stub.request(
      :learnanalytics, :get, "/course_statistics/#{course_id2}"
    ).to_return Stub.json(NotificationService::CourseStats.verify({
      id: '00d6833d-d75c-4f64-813f-5d312bd7e683',
      course_code: 'prep',
      course_id: course_id2,
      course_status: 'preparation',
      start_date: 4.days.from_now,
      end_date: 12.days.from_now,
      created_at: '2016-09-14T09:11:53.781Z',
      updated_at: '2016-09-14T11:29:57.596Z',

      active_users_last_7days: nil,
      active_users_last_day: nil,
      badge_downloads: nil,
      badge_issues: nil,
      badge_shares: nil,
      completion_rate: 0.0,
      consumption_rate: 0.0,
      cop_count: nil,
      current_enrollments: 0,
      days_since_coursestart: nil,
      enrollments_at_course_end_netto: 0,
      enrollments_at_course_end: 0,
      enrollments_at_course_middle_netto: 0,
      enrollments_at_course_middle: 0,
      enrollments_at_course_start_netto: 0,
      enrollments_at_course_start: 0,
      enrollments_last_day: 0,
      enrollments_per_day: [0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      helpdesk_tickets_last_day: 0,
      helpdesk_tickets: 0,
      hidden: false,
      new_users: 0,
      no_shows_at_end: 0,
      no_shows_at_middle: 0,
      no_shows: 0,
      posts_last_day: 0,
      posts: 0,
      qc_count: nil,
      roa_count: 0,
      shows_at_end: 0,
      shows_at_middle: 0,
      shows: 0,
      threads_last_day: 0,
      threads: 0,
      total_enrollments: 0,
    }))

    Stub.request(
      :learnanalytics, :get, "/course_statistics/#{course_id3}"
    ).to_return Stub.json(NotificationService::CourseStats.verify({
      id: '00d6833d-d75c-4f64-813f-5d312bd7e682',
      course_code: 'aff',
      course_id: course_id3,
      course_status: 'active',
      start_date: 4.days.ago,
      end_date: 2.days.ago,
      created_at: '2016-09-14T09:11:53.781Z',
      updated_at: '2016-09-14T11:29:57.596Z',

      active_users_last_7days: nil,
      active_users_last_day: nil,
      badge_downloads: nil,
      badge_issues: nil,
      badge_shares: nil,
      completion_rate: 0.0,
      consumption_rate: 0.0,
      cop_count: nil,
      current_enrollments: 0,
      days_since_coursestart: nil,
      enrollments_at_course_end_netto: 0,
      enrollments_at_course_end: 0,
      enrollments_at_course_middle_netto: 0,
      enrollments_at_course_middle: 0,
      enrollments_at_course_start_netto: 0,
      enrollments_at_course_start: 0,
      enrollments_last_day: 0,
      enrollments_per_day: [0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      helpdesk_tickets_last_day: 0,
      helpdesk_tickets: 0,
      hidden: false,
      new_users: 0,
      no_shows_at_end: 0,
      no_shows_at_middle: 0,
      no_shows: 0,
      posts_last_day: 0,
      posts: 0,
      qc_count: nil,
      roa_count: 0,
      shows_at_end: 0,
      shows_at_middle: 0,
      shows: 0,
      threads_last_day: 0,
      threads: 0,
      total_enrollments: 0,
    }))

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

    # Helpdesk tickets
    create_list(:helpdesk_ticket, 5)
    create_list(:helpdesk_ticket, 5, :today)
  end

  describe 'global statistic mail' do
    let(:mail) { subject; ActionMailer::Base.deliveries.first }

    before { Xikolo.config.statistics_email_recipients = ['admins@the-platform.org'] }

    it 'has the correct subject line' do
      expect(mail.subject).to include 'Daily admin statistics for '
    end

    it 'has the correct sender email' do
      expect(mail.from).to eq(['no-reply@xikolo.de'])
    end

    it 'sends a multipart email' do
      expect(mail).to be_multipart
    end

    it 'contains correct information in its body' do
      # Headlines
      expect(mail.html).to include 'Xikolo statistics'
      expect(mail.html).to include 'Users on Xikolo'
      expect(mail.html).to include 'New Course Enrollments'
      expect(mail.html).to include 'Upcoming courses'
      expect(mail.html).to include 'Current courses'

      # Numbers
      expect(mail.html).to include '322'
      expect(mail.html).to include '42'
      expect(mail.html).to include '100'
      expect(mail.html).to include '10'
      expect(mail.html).to include '5'

      # Course start info
      expect(mail.html).to include 'Starts in 4 days'

      # Course name
      expect(mail.html).to include 'Software Profiling Future'
      expect(mail.html).not_to include 'Course in Preparation'
      expect(mail.html).to include 'Company Course'

      # Users
      expect(mail.html).to include 'Users'
    end

    context 'based on config' do
      before do
        Xikolo.config.mailsender = 'foo@bar.com'
      end

      it 'sends from the configured email address' do
        expect(mail.from).to eq(['foo@bar.com'])
      end
    end
  end

  describe 'course admin mail' do
    let(:course_mail) { subject; ActionMailer::Base.deliveries.last }

    it 'has the correct subject line' do
      expect(course_mail.subject).to include 'Your daily course statistics for '
    end

    it 'does not includes global info' do
      expect(course_mail.html).not_to include 'Xikolo statistics'
    end

    it 'contains correct information in its body' do
      # Headlines
      expect(course_mail.html).not_to include 'Xikolo statistics'
      expect(course_mail.html).not_to include 'Users on Xikolo'
      expect(course_mail.html).to include 'New Course Enrollments'
      expect(course_mail.html).not_to include 'Full course list'
      expect(course_mail.html).to include 'Upcoming courses'
      expect(course_mail.html).to include 'Current courses'
      expect(course_mail.html).to include 'futcode' # course_code
    end
  end
end
