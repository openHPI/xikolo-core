# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Signed URL', type: :request do
  subject(:get_signed_url) { get "/learn/#{course.course_code}/items/#{item.id}/signed_url" }

  let(:course) { create(:course, course_code: 'example') }
  let(:section) { create(:section, course:) }
  let(:video) { create(:video, pip_stream: create(:stream, :bunny, provider_video_id: 'bunny-guid')) }
  let(:item) { create(:item, section:, content_type: 'video', content_id: video.id) }
  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item_resource) do
    build(:'course:item',
      id: item.id, section_id: section.id, course_id: course.id,
      content_id: video.id, content_type: 'video', title: item.title)
  end

  before do
    sign_in(user:)
    role = create(:'account_service/role', permissions: %w[course.content.access.available])
    create(:'account_service/grant', principal: user, role:)

    Stub.request(:course, :get, "/courses/#{course.course_code}").to_return Stub.json(course_resource)
    Stub.request(:course, :get, "/items/#{item.id}", query: {user_id:}).to_return Stub.json(item_resource)
    Stub.request(:course, :get, "/sections/#{section.id}").to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id}).to_return Stub.json([section_resource])
  end

  context 'with a bunny video item' do
    it 'redirects to a signed bunny playlist url' do
      get_signed_url

      expect(response).to have_http_status(:found)
      expect(response.location).to include '/bunny-guid/playlist.m3u8'
    end
  end

  context 'with a vimeo video item' do
    let(:video) { create(:video, pip_stream: create(:stream, :vimeo)) }
    let(:item_resource) { build(:'course:item', id: item.id, section_id: section.id, course_id: course.id, content_id: video.id, content_type: 'video', title: item.title) }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end

  context 'with a non video item' do
    let(:item) { create(:item, :richtext, section:) }
    let(:item_resource) { build(:'course:item', id: item.id, section_id: section.id, course_id: course.id, content_id: item.content_id, content_type: 'rich_text', title: item.title) }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end

  context 'when the item belongs to a different course' do
    let(:other_course) { create(:course, course_code: 'other') }
    let(:other_section) { create(:section, course: other_course) }
    let(:item) { create(:item, section: other_section, content_type: 'video', content_id: video.id) }

    it 'is not found' do
      expect { get_signed_url }.to raise_error(Status::NotFound)
    end
  end
end
