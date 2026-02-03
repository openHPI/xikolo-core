# frozen_string_literal: true

require 'spec_helper'

describe 'Transpipe API: Show course', type: :request do
  subject(:request) { get "/bridges/transpipe/courses/#{course_id}", headers: }

  let(:headers) { {'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966'} }
  let(:json) { JSON.parse response.body }
  let(:course) { build(:'course:course') }
  let(:teachers) { [build(:'course:teacher')] }
  let(:course_id) { course['id'] }
  let(:section_id) { sections.first['id'] }
  let(:item_id) { videos.first['id'] }
  let(:video_id) { videos.first['content_id'] }

  let(:sections) { [build(:'course:section')] }
  let(:videos) do
    [
      build(:'course:item', :video, section_id:),
      build(:'course:item', :video, section_id:),
    ]
  end

  before do
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json(course)
    Stub.request(:course, :get, '/sections', query: {course_id:})
      .to_return Stub.json(sections)
    Stub.request(:course, :get, '/items', query: {course_id:, content_type: 'video'})
      .to_return Stub.json(videos)
    Stub.request(:course, :get, '/teachers', query: {course: course_id})
      .to_return Stub.json(teachers)
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  it 'responds with the correct object structure' do
    request
    expect(response).to have_http_status :ok
    expect(json).to include(
      'title',
      'abstract',
      'language',
      'start-date',
      'end-date',
      'status',
      'sections',
      'teachers',
      'alternative_teacher_text',
      'id' => course_id
    )
    expect(json['sections'].first).to include(
      'title',
      'accessible',
      'start-date',
      'videos',
      'id' => section_id
    )
    expect(json['sections'].first['videos'].first).to include(
      'title',
      'accessible',
      'start-date',
      'id' => video_id,
      'item-id' => item_id
    )
    expect(json['teachers'].first).to include(
      'id',
      'name'
    )
  end

  describe 'authorization / error handling' do
    let(:course_id) { generate(:course_id) }

    context 'when the course does not exist' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.response(status: 404)
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end

    context 'trying to access an external course' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.json build(:'course:course', id: course_id, external_course_url: 'https://teach.me.stuff')
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
