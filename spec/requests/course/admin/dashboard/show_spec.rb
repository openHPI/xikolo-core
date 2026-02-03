# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Dashboard: Show', type: :request do
  subject(:show_course_dashboard) do
    get "/courses/#{course.course_code}/dashboard",
      headers:
  end

  let(:headers) { {} }
  let(:permissions) { [] }
  let(:features) { {} }
  let(:course) { create(:course, end_date: 1.week.ago, records_released: true) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code, end_date: 1.week.ago,
      records_released: true)
  end

  before do
    stub_user_request(permissions:, features:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    allow(Admin::Statistics::AgeDistribution).to receive(:call).and_return([])

    Stub.request(:course, :get, '/items', query: hash_including({
      course_id: course.id,
      was_available: 'true',
      content_type: 'quiz',
      exercise_type: 'main,bonus',
    })).to_return Stub.json([])
    Stub.request(:course, :get, '/items', query: hash_including({
      course_id: course.id,
      was_available: 'true',
      content_type: 'quiz',
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

    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, '/course_statistics', query: hash_including(
      course_id: course.id,
      historic_data: 'true'
    )).to_return Stub.json([])
    Stub.request(:learnanalytics, :get, '/metrics')
      .to_return Stub.json([
        {'name' => 'client_combination_usage', 'available' => true},
        {'name' => 'item_visits_count', 'available' => true},
        {'name' => 'video_play_count', 'available' => true},
        {'name' => 'forum_activity', 'available' => true},
        {'name' => 'forum_write_activity', 'available' => true},
        {'name' => 'certificates', 'available' => true},
      ])
    Stub.request(
      :learnanalytics, :get, '/metrics/client_combination_usage',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :learnanalytics, :get, '/metrics/item_visits_count',
      query: hash_including({course_id: course.id})
    ).to_return Stub.json({})
    Stub.request(
      :learnanalytics, :get, '/metrics/video_play_count',
      query: hash_including({course_id: course.id})
    ).to_return Stub.json({})
    Stub.request(
      :learnanalytics, :get, '/metrics/forum_activity',
      query: hash_including({course_id: course.id})
    ).to_return Stub.json({})
    Stub.request(
      :learnanalytics, :get, '/metrics/forum_write_activity',
      query: hash_including({course_id: course.id})
    ).to_return Stub.json({})
    Stub.request(
      :learnanalytics, :get, '/metrics/certificates',
      query: hash_including({course_id: course.id})
    ).to_return Stub.json({
      record_of_achievement: 4,
      confirmation_of_participation: 6,
      qualified_certificate: 1,
    })
  end

  context 'as anonymous user' do
    it 'redirects the user' do
      show_course_dashboard
      expect(response).to redirect_to course_url(course.course_code)
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'redirects the user' do
      show_course_dashboard
      expect(response).to redirect_to course_url(course.course_code)
    end

    context 'with permissions' do
      let(:permissions) { %w[course.dashboard.view course.content.access] }

      it 'renders age distribution and client usage tables' do
        show_course_dashboard
        expect(response).to render_template :show
        expect(response.body).to include 'Age Distribution'
        expect(response.body).to include 'Client Usage'
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

      context 'with CoP details feature flipper' do
        let(:features) { {'course_dashboard.show_cops_details' => true} }

        it 'displays CoP details' do
          show_course_dashboard
          expect(response.body).to include 'CoPs until course end'
          expect(response.body).to include 'CoPs after course end'
        end
      end
    end
  end
end
