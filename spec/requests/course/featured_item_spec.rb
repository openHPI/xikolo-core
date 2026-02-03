# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Featured items', type: :request do
  subject(:show_course) do
    get '/courses/the-course', headers:
  end

  # We build this spec for a logged-in user since the anonymous user does not come with the default permissions. (course.course.show)
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course, course_code: 'the-course', status: 'active') }
  let(:section) { create(:section, course:) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:featured_item) { create(:item, :video, title: 'Featured item', section:, featured: true) }
  let(:featured_item_2) { create(:item, :video, title: 'Featured item 2', section:, featured: true) }
  let(:item) { create(:item, :video, title: 'Regular item', section:, featured: false) }

  before do
    stub_user_request id: user_id, permissions: %w[course.course.show]

    Stub.request(
      :course, :get, '/courses/the-course'
    ).to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/items',
      query: {content_type: 'video', course_id: course.id, featured: 'true'}
    ).to_return Stub.json([featured_item, featured_item_2])
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including(user_id:, course_id: course.id)
    ).to_return Stub.json([])
  end

  it 'only lists the featured video items on the course page' do
    show_course

    expect(response).to be_successful
    expect(response.body).to include('Featured content')
    expect(response.body).to include('Featured item')
    expect(response.body).to include('Featured item 2')
    expect(response.body).not_to include('Regular item')
  end
end
