# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Launch', type: :request do
  subject(:launch_course) { get launch_url, headers: }

  let(:headers) { {} }
  let(:launch_url) { "/courses/#{course_code}/launch" }
  let(:course_code) { 'the-course' }
  let(:course) { build(:'course:course', course_code:, title: 'The course') }

  before do
    Stub.request(
      :course, :get, "/courses/#{course_code}"
    ).to_return Stub.json(course)
  end

  context 'for anonymous user' do
    before do
      launch_course
    end

    it 'redirects to login' do
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end

    it 'asks user to login to proceed' do
      follow_redirect!
      expect(response.body).to include('Please login to enroll to the course: <b>The course</b>')
    end

    it 'stores the enrollment path as location' do
      follow_redirect!
      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      expect(jar.signed['stored_location']).to eq("/enrollments?course_id=#{course_code}")
    end
  end

  context 'for authorized user' do
    let(:headers) { {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"} }

    before do
      stub_user_request
      launch_course
    end

    it 'redirects to the enrollment creation' do
      expect(response).to redirect_to "/enrollments?course_id=#{course_code}"
    end
  end

  context 'with auth provider' do
    let(:provider) { 'saml' }
    let(:launch_url) { "/courses/#{course_code}/launch/#{provider}" }

    before { launch_course }

    it 'redirects to SSO authentication' do
      expect(response).to redirect_to "/auth/#{provider}"
    end

    it 'stores the enrollment path as location' do
      follow_redirect!
      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      expect(jar.signed['stored_location']).to eq("/enrollments?course_id=#{course_code}")
    end
  end
end
