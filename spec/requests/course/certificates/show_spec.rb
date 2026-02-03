# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Show', type: :request do
  subject(:show_certificate) { get "/courses/#{course.id}/certificate", headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:course) { create(:course, course_code: 'my-course', records_released: true) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:user) { create(:user, :with_email) }
  let!(:certificate_template) { create(:certificate_template, :roa, course:) }
  let!(:badge_template) { create(:open_badge_template, course:) }
  let(:enrollments) do
    build_list(
      :'course:enrollment', 1,
      course_id: course.id,
      user_id: user.id,
      points: {achieved: 90, maximal: 100, percentage: 90},
      certificates: {record_of_achievement: true, certificate: true},
      quantile: 0.99
    )
  end

  before do
    xi_config file_fixture('badge_config.yml').read

    stub_user_request id: user.id

    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
    ).to_return Stub.json(enrollments)
  end

  context 'with achieved Record of Achievement' do
    let(:record) { create(:roa, course:, user:, template: certificate_template) }
    let(:open_badge) { create(:open_badge, record:, open_badge_template: badge_template) }
    let(:file_url) { "https://s3.xikolo.de/xikolo-certificate/openbadges/#{UUID4(user.id).to_s(format: :base62)}/#{UUID4(record.id).to_s(format: :base62)}.png" }

    before do
      stub_request(:get, open_badge.open_badge_template.file_uri.gsub('s3://', 'https://s3.xikolo.de/'))
        .with(query: hash_including({}))
        .to_return(body: File.new('spec/support/files/certificate/badge_template.png'), status: 200)
      stub_request(:put, file_url)
    end

    it 'shows the Record of Achievement' do
      show_certificate
      expect(response).to have_http_status :ok
      expect(response.body).to include 'Record of Achievement'
      expect(response.body).to include course['title']
    end

    it 'shows the Open Badge' do
      show_certificate
      expect(response.body).to include 'open-badge-download'
    end
  end

  context 'with no Record of Achievement achieved for the course' do
    let(:enrollments) do
      build_list(
        :'course:enrollment', 1,
        course_id: course.id,
        user_id: user.id,
        points: {achieved: 0, maximal: 100, percentage: 0},
        certificates: {}
      )
    end

    it 'responds with 404 Not Found' do
      expect { show_certificate }.to raise_error AbstractController::ActionNotFound
    end
  end
end
