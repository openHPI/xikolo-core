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

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    allow(Admin::Statistics::AgeDistribution).to receive(:call).and_return([])

    encoded_end_date = CGI.escape((DateTime.parse(course_resource['end_date']) + 12.weeks).strftime('%Y-%m-%dT%H:%M:%S%:z'))

    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, "/course_statistics?course_id=#{course.id}&end_date=#{encoded_end_date}&historic_data=true&start_date")
      .to_return Stub.json([])
    Stub.request(:learnanalytics, :get, '/metrics')
      .to_return Stub.json([
        {'name' => 'client_combination_usage', 'available' => true},
      ])
    Stub.request(
      :learnanalytics, :get, '/metrics/client_combination_usage',
      query: hash_including({})
    ).to_return Stub.json([])
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

      it 'does not display the CoP details' do
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

      it 'renders age distribution and client usage tables' do
        show_course_dashboard
        expect(response).to render_template :show
        expect(response.body).to include 'Age Distribution'
        expect(response.body).to include 'Client Usage'
      end
    end
  end
end
