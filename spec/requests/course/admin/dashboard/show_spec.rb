# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Dashboard: Show', type: :request do
  subject(:show_course_dashboard) do
    get "/learn/#{course.course_code}/dashboard"
  end

  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }
  let(:course) { create(:'course_service/course', end_date: 1.week.ago, records_released: true) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code, end_date: 1.week.ago,
      records_released: true)
  end

  before do
    sign_in(user:) if authenticate

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)

    allow(Admin::Statistics::AgeDistribution).to receive(:call).and_return([])

    Stub.request(:course, :get, '/items', query: hash_including({
      course_id: course.id,
      was_available: 'true',
      content_type: 'QuizService::Quiz',
      exercise_type: 'main,bonus',
    })).to_return Stub.json([])
    Stub.request(:course, :get, '/items', query: hash_including({
      course_id: course.id,
      was_available: 'true',
      content_type: 'QuizService::Quiz',
      exercise_type: 'selftest',
    })).to_return Stub.json([])
    Stub.request(:quiz, :get, '/submission_statistic', query: hash_including({}))
      .to_return Stub.json({})
    Stub.request(:pinboard, :get, "/statistics/#{course.id}")
      .to_return Stub.json({})

    Stub.request(
      :course, :get, '/stats',
      query: {key: 'enrollments', course_id: course.id}
    ).to_return Stub.json({
      enrollments: 8,
      enrollments_netto: 8,
      enrollments_last_day: 0,
      enrollments_at_start: 5,
      enrollments_at_start_netto: 5,
      enrollments_at_middle: 7,
      enrollments_at_middle_netto: 7,
      enrollments_at_end: 8,
      enrollments_at_end_netto: 8,
    })
    Stub.request(
      :course, :get, '/stats',
      query: {key: 'shows_and_no_shows', course_id: course.id}
    ).to_return Stub.json({
      shows: 5,
      shows_at_middle: 4,
      shows_at_end: 3,
    })
  end

  context 'as anonymous user' do
    let(:authenticate) { false }

    it 'redirects the user' do
      show_course_dashboard
      expect(response).to redirect_to course_url(course.course_code)
    end
  end

  context 'as logged in user' do
    it 'redirects the user' do
      show_course_dashboard
      expect(response).to redirect_to course_url(course.course_code)
    end

    context 'with permissions' do
      before do
        role = create(:'account_service/role', permissions: %w[course.dashboard.view course.content.access])
        create(:'account_service/grant', principal: user, role:)
      end

      it 'renders age distribution table' do
        show_course_dashboard
        expect(response).to render_template :show
        expect(response.body).to include 'Age Distribution'
      end

      it 'renders KPI cards and KPI score cards' do
        show_course_dashboard
        expect(response.body).to include 'Enrollments'
        expect(response.body).to include 'Activity'
        expect(response.body).to include 'Certificates'
        expect(response.body).to include 'Learning Items'
        expect(response.body).to include 'Forum'
      end

      it 'does not display the CoP details by default' do
        show_course_dashboard
        expect(response.body).to include 'Confirmations of Participation'
        expect(response.body).not_to include 'CoPs until course end'
        expect(response.body).not_to include 'CoPs after course end'
      end
    end
  end
end
