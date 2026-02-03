# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ajax: Courses: Index', type: :request do
  let(:find_courses) { get '/admin/find_courses', params:, headers: }
  let(:headers) do
    {
      Authorization: "Xikolo-Session session_id=#{stub_session_id}",
      'X-Requested-With': 'XMLHttpRequest',
    }
  end
  let(:permissions) { %w[course.course.index] }
  let(:params) { {q: 'course1'} }
  let(:json) { response.parsed_body }

  let(:course1) do
    build(:'course:course', title: 'My course 1', course_code: 'my-course-1')
  end
  let(:course2) do
    build(:'course:course', title: 'My course 2', course_code: 'my-course-2')
  end

  before do
    stub_user_request(permissions:)

    Stub.request(
      :course, :get, '/courses',
      query: hash_including(
        autocomplete: 'course1',
        limit: '50'
      )
    ).to_return Stub.json([course1, course2])
  end

  context 'as an AJAX request' do
    it 'lists all matched courses' do
      find_courses
      expect(json).to contain_exactly({'id' => course1['id'], 'text' => 'My course 1 (my-course-1)'}, {'id' => course2['id'], 'text' => 'My course 2 (my-course-2)'})
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'responds with 403 Forbidden' do
      find_courses
      expect(response).to have_http_status :forbidden
    end
  end

  context 'for anonymous users' do
    let(:headers) { {'X-Requested-With': 'XMLHttpRequest'} }

    it 'responds with 403 Forbidden' do
      find_courses
      expect(response).to have_http_status :forbidden
    end
  end

  context 'as an HTTP request' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'does not respond with HTML' do
      expect { find_courses }.to raise_error ActionController::RoutingError
    end
  end
end
