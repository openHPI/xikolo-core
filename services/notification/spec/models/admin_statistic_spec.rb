# frozen_string_literal: true

require 'spec_helper'

describe AdminStatistic, type: :model do
  subject(:statistic) { described_class.new }

  let(:course_id) { '00000001-3300-4444-9999-000000000006' }
  let(:course_id2) { '00000001-3300-4444-9999-000000000007' }
  let(:course_id3) { '00000001-3300-4444-9999-000000000008' }

  let(:end_date) { '2017-08-16T00:00:00.000Z' }
  let(:course_statistic) do
    CourseStats.verify({
      id: '00d6833d-d75c-4f64-813f-5d312bd7e686',
      course_code: 'hidden',
      course_id: '00000001-3300-4444-9999-000000000007',
      course_status: 'active',
      hidden: true,
      end_date:,
      start_date: nil,
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
      enrollments_at_course_end_netto: nil,
      enrollments_at_course_end: nil,
      enrollments_at_course_middle_netto: nil,
      enrollments_at_course_middle: 0,
      enrollments_at_course_start_netto: nil,
      enrollments_at_course_start: nil,
      enrollments_last_day: 0,
      enrollments_per_day: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      helpdesk_tickets_last_day: 0,
      helpdesk_tickets: 0,
      new_users: 0,
      no_shows_at_end: nil,
      no_shows_at_middle: nil,
      no_shows: 0.0,
      posts_last_day: nil,
      posts: nil,
      qc_count: nil,
      roa_count: 99,
      shows_at_end: nil,
      shows_at_middle: nil,
      shows: nil,
      threads_last_day: nil,
      threads: nil,
      total_enrollments: 100,
    })
  end

  before do
    Sidekiq::Testing.fake!

    Stub.service(
      :learnanalytics,
      root_url: '/',
      course_statistics_url: '/course_statistics',
      new_course_statistic_url: '/course_statistics/new',
      edit_course_statistic_url: '/course_statistics/{id}/edit',
      course_statistic_url: '/course_statistics/{id}',
      metric_url: '/metric'
    )

    Stub.request(:learnanalytics, :get, "/course_statistics/#{course_id}")
      .to_return Stub.json(course_statistic)

    Stub.request(:learnanalytics, :get, "/course_statistics/#{course_id2}")
      .to_return Stub.json(course_statistic)

    Stub.request(:learnanalytics, :get, "/course_statistics/#{course_id3}")
      .to_return Stub.json(course_statistic)

    Stub.request(
      :learnanalytics, :get, '/metric',
      query: {name: 'certificates'}
    )

    Stub.service(:course,
      courses_url: '/courses',
      stats_url: '/stats')

    Stub.request(
      :course, :get, '/courses',
      query: {groups: 'any'}
    ).to_return Stub.json([
      {id: course_id, title: 'Software Profiling Future'},
      {id: course_id2, title: 'Course in Preparation', status: 'preparation'},
      {id: course_id3, title: 'Company X Course', affiliated: true},
    ])

    Stub.request(
      :course, :get, '/stats',
      query: {course_id:}
    ).to_return Stub.json({
      enrollments: 100,
      last_day_enrollments: 10,
    })

    Stub.request(
      :course, :get, '/stats',
      query: {course_id: course_id3}
    ).to_return Stub.json({
      enrollments: 200,
      last_day_enrollments: 20,
    })

    Stub.request(
      :course, :get, '/stats',
      query: {key: 'global'}
    ).to_return Stub.json({})

    Stub.request(
      :course, :get, '/stats',
      query: {course_id:, key: 'extended'}
    ).to_return Stub.json({
      certificates_count: 99,
    })

    Stub.request(
      :course, :get, '/stats',
      query: {course_id: course_id3, key: 'extended'}
    ).to_return Stub.json({
      certificates_count: 10,
    })

    Stub.request(
      :course, :get, '/stats',
      query: {course_id:, key: 'enrollments_by_day'}
    ).to_return Stub.json({
      student_enrollments_by_day: {DateTime.now.iso8601 => 199},
    })

    Stub.request(
      :course, :get, '/stats',
      query: {course_id: course_id3, key: 'enrollments_by_day'}
    ).to_return Stub.json({
      student_enrollments_by_day: {DateTime.now.iso8601 => 199},
    })

    Stub.service(
      :pinboard,
      statistics_url: '/statistics'
    )

    Stub.request(
      :pinboard, :get, '/statistics'
    ).to_return Stub.json({
      questions: 500,
      questions_last_day: 50,
    })

    Stub.service(
      :account,
      statistics_url: '/statistics'
    )

    Stub.request(
      :account, :get, '/statistics'
    )

    # Helpdesk tickets
    create_list(:helpdesk_ticket, 5)
    create_list(:helpdesk_ticket, 5, :today)
  end

  it 'has one course' do
    expect(statistic).to respond_to(:course_stats)
    expect(statistic.course_stats.length).to eq(2)

    course_info = statistic.course_stats.first
    expect(course_info).to be_a(CourseStats)
    expect(course_info.course_id).to eq(course_id2)
  end

  it 'has general course statistics' do
    expect(statistic).to respond_to(:platform_course_stats)
  end

  it 'has correct data' do
    course_statistic = statistic.course_stats.first
    expect(course_statistic.course_id).to eq(course_id2)
    expect(course_statistic.total_enrollments).to eq(100)
    expect(course_statistic.roa_count).to eq(99)
  end

  it 'counts helpdesk tickets (total and per day)' do
    expect(statistic.helpdesk.ticket_count).to eq 10
    expect(statistic.helpdesk.ticket_count_last_day).to eq 5
  end

  context 'without an end date' do
    let(:end_date) { nil }

    it 'does not raise an error' do
      expect { statistic }.not_to raise_error
    end
  end
end
