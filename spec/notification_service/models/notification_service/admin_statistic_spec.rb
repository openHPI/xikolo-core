# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::AdminStatistic, type: :model do
  subject(:statistic) { described_class.new }

  let(:course_id) { '00000001-3300-4444-9999-000000000006' }
  let(:course_id2) { '00000001-3300-4444-9999-000000000007' }
  let(:course_id3) { '00000001-3300-4444-9999-000000000008' }

  before do
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

    Stub.request(
      :pinboard, :get, '/statistics'
    ).to_return Stub.json({
      questions: 500,
      questions_last_day: 50,
    })

    Stub.request(
      :account, :get, '/statistics'
    )

    # Helpdesk tickets
    create_list(:helpdesk_ticket, 5)
    create_list(:helpdesk_ticket, 5, :today)
  end

  it 'has general course statistics' do
    expect(statistic).to respond_to(:platform_course_stats)
  end

  it 'counts helpdesk tickets (total and per day)' do
    expect(statistic.helpdesk.ticket_count).to eq 10
    expect(statistic.helpdesk.ticket_count_last_day).to eq 5
  end

  context 'without an end date' do
    it 'does not raise an error' do
      expect { statistic }.not_to raise_error
    end
  end
end
