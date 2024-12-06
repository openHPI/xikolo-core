# frozen_string_literal: true

require 'spec_helper'

describe 'Statistics: Certificates Stats' do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  subject(:response) do
    get "/v2/statistics/course_dashboard/enrollments.json?course_id=#{course.id}", nil, env_hash
  end

  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course, :archived, context_id:) }
  let(:course_resource) { build(:'course:course', id: course.id, start_date: course.start_date, end_date: course.end_date) }
  let(:context_id) { generate(:uuid) }
  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'rack.session' => {id: stub_session_id},
    }
  end
  let(:enrollment_stats) { {enrollments: 15} }
  let(:shows_and_no_shows_stats) do
    {shows: 15, shows_at_end: 10}
  end
  let(:certificates) do
    {record_of_achievement: 7, confirmation_of_participation: 13}
  end
  let(:certificates_after_end) do
    {record_of_achievement: 3, confirmation_of_participation: 5}
  end
  let(:certificates_at_end) do
    {record_of_achievement: 4, confirmation_of_participation: 8}
  end

  before do
    api_stub_user id: user_id, permissions: %w[course.dashboard.view]

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course.id}"
    ).to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/stats',
      query: {key: 'enrollments', course_id: course.id}
    ).to_return Stub.json(enrollment_stats)
    Stub.request(
      :course, :get, '/stats',
      query: {key: 'shows_and_no_shows', course_id: course.id}
    ).to_return Stub.json(shows_and_no_shows_stats)

    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(
      :learnanalytics, :get, '/metrics'
    ).to_return Stub.json([{'name' => 'certificates', 'available' => true}])
    Stub.request(
      :learnanalytics, :get, '/metrics/certificates',
      query: {course_id: course.id}
    ).to_return Stub.json(certificates)
    Stub.request(
      :learnanalytics, :get, '/metrics/certificates',
      query: {course_id: course.id, start_date: course.start_date.iso8601(3), end_date: course.end_date.iso8601(3)}
    ).to_return Stub.json(certificates_at_end)
    Stub.request(
      :learnanalytics, :get, '/metrics/certificates',
      query: {course_id: course.id, start_date: course.end_date.iso8601(3)}
    ).to_return Stub.json(certificates_after_end)
  end

  it 'includes certificate statistics' do
    expect(JSON.parse(response.body)).to include(
      'cop_at_end_count' => 8,
      'cop_after_end_count' => 5,
      'consumption_rate_at_end' => 80,
      'consumption_rate_after_end' => 100,
      'consumption_rate_current' => 86
    )
  end

  context 'with statistics not available (since the course has not yet ended)' do
    let(:course) { create(:course, :active, context_id:) }
    let(:shows_and_no_shows_stats) do
      {shows: 50, shows_at_end: nil}
    end
    let(:certificates) do
      {record_of_achievement: 8, confirmation_of_participation: 12}
    end
    let(:certificates_after_end) do
      {record_of_achievement: nil, confirmation_of_participation: nil}
    end
    let(:certificates_at_end) do
      {record_of_achievement: 8, confirmation_of_participation: 12}
    end

    it 'includes certificate statistics' do
      expect(JSON.parse(response.body)).to include(
        'cop_at_end_count' => 12,
        'cop_after_end_count' => nil,
        'consumption_rate_at_end' => 0,
        'consumption_rate_after_end' => 0,
        'consumption_rate_current' => 24
      )
    end
  end
end
