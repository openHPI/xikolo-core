# frozen_string_literal: true

require 'spec_helper'

describe AdminStatistic, type: :model do
  let(:course_id) { '00000001-3300-4444-9999-000000000006' }
  let(:course_id2) { '00000001-3300-4444-9999-000000000007' }
  let(:course_id3) { '00000001-3300-4444-9999-000000000008' }

  let(:statistic) { AdminStatistic.new }

  let(:course_statistic) do
    {
      id: '00d6833d-d75c-4f64-813f-5d312bd7e686',
      course_code: 'hidden',
      course_name: 'Company X Course',
      course_id: '00000001-3300-4444-9999-000000000007',
      course_status: 'active',
      total_enrollments: 100,
      no_shows: 0.0,
      current_enrollments: 0,
      enrollments_last_24h: 0,
      enrollments_at_course: 0,
      enrollments_at_course_middle_incl_unenrollments: 0,
      enrollments_at_course_middle: 0,
      enrollments_at_course_end: nil,
      questions: 500,
      questions_last_24h: 50,
      answers: 0,
      answers_last_24h: 0,
      comments_on_answers: 0,
      comments_on_answers_last_24h: 0,
      comments_on_questions: 0,
      comments_on_questions_last_24h: 0,
      roa_count: 99,
      helpdesk_tickets: 0,
      helpdesk_tickets_last_24h: 0,
      start_date: '2017-06-15T00:00:00.000Z',
      end_date: '2017-08-16T00:00:00.000Z',
      new_users: 0,
      created_at: '2016-09-14T09:11:53.781Z',
      updated_at: '2016-09-14T11:29:57.596Z',
      completion_rate: 0.0,
      consumption_rate: 0.0,
      enrollments_per_day: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      hidden: true,
    }
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

    expect(course_info).to be_a(Restify::Resource)
    expect(course_info.keys).to match_array %w[
      id
      course_code
      course_name
      course_id
      course_status
      total_enrollments
      no_shows
      current_enrollments
      enrollments_last_24h
      enrollments_at_course
      enrollments_at_course_middle_incl_unenrollments
      enrollments_at_course_middle
      enrollments_at_course_end
      questions
      questions_last_24h
      answers
      answers_last_24h
      comments_on_answers
      comments_on_answers_last_24h
      comments_on_questions
      comments_on_questions_last_24h
      roa_count
      helpdesk_tickets
      helpdesk_tickets_last_24h
      start_date
      end_date
      new_users
      created_at
      updated_at
      completion_rate
      consumption_rate
      enrollments_per_day
      hidden
    ]

    expect(course_info.course_id).to eq(course_id2)
    expect(course_info.course_name).to eq('Company X Course')
  end

  it 'has general course statistics' do
    expect(statistic).to respond_to(:platform_course_stats)
  end

  it 'has correct data' do
    course_statistic = statistic.course_stats.first
    expect(course_statistic.course_id).to eq(course_id2)
    expect(course_statistic.total_enrollments).to eq(100)
    expect(course_statistic.questions).to eq(500)
    expect(course_statistic.questions_last_24h).to eq(50)
    expect(course_statistic.roa_count).to eq(99)
  end

  it 'counts helpdesk tickets (total and per day)' do
    expect(statistic.helpdesk.ticket_count).to eq 10
    expect(statistic.helpdesk.ticket_count_last_day).to eq 5
  end
end
