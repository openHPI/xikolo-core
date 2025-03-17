# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Item: TransPipe: Create Item', type: :system do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let(:course) { create(:course, course_code: 'the_course') }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section) { create(:section, course: course, title: 'Week 1') }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id, title: section.title) }
  let!(:stream) { create(:stream, title: 'the_course_pip1') }
  let(:new_video) { build(:video, pip_stream_id: stream.id) }
  let(:new_item) { build(:item, section: section, content: new_video) }
  let(:new_item_resource) do
    build(:'course:item', :video,
      id: new_item.id,
      course_id: course.id,
      section_id: section.id,
      content_id: new_video.id)
  end

  before do
    stub_user id: user_id, permissions: %w[course.content.access course.content.edit video.video.index]
    Stub.service(:course, build(:'course:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:account, :get, "/users/#{user_id}").to_return Stub.json(user)
    Stub.request(:course, :get, '/courses/the_course').to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section.id}").to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json([section_resource])
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
      .to_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including({})).to_return Stub.json([])
    Stub.request(:pinboard, :post, '/implicit_tags',
      body: hash_including(course_id: course.id, referenced_resource: 'Xikolo::Course::Item')).to_return Stub.json({})
  end

  it 'allows subtitle uploads via the platform and does not show the TransPipe link by default' do
    visit "/courses/the_course/sections/#{section.id}/items/new"
    expect(page).to have_content 'Create new item in section "Week 1"'

    select 'Video', from: 'Type'

    within_fieldset('Video Data') do
      expect(page).to have_content 'Subtitles'
      expect(page).to have_css('.xui-upload[data-id="video_subtitles"]')
      expect(page).to have_no_link 'Manage subtitles in TransPipe'
    end
  end

  context 'with TransPipe enabled' do
    let(:create_item_request) do
      Stub.request(:course, :post, '/items').to_return Stub.json(new_item_resource)
    end

    before do
      xi_config <<~YML
        transpipe:
          enabled: true
          course_video_url_template: https://transpipe.example.com/link/platform/courses/{course_id}/videos/{video_id}
      YML
      create_item_request
    end

    it 'hides the subtitle upload' do
      visit "/courses/the_course/sections/#{section.id}/items/new"
      expect(page).to have_content 'Create new item in section "Week 1"'

      # xi-course creates the node after creating the item, but the item creation is stubbed here.
      # Creating the node takes some time, so if it's positioned close to "click on 'Create Item'",
      # it might cause the test to become flaky.
      create(:item_node, item: new_item, course:, parent_id: section.node.id)

      fill_in 'Title', with: 'Video without subtitles'
      select 'Video', from: 'Type'

      tom_select '_pip1', from: 'Pip stream', search: true

      within_fieldset('Video Data') do
        # No need for a label.
        expect(page).to have_no_content 'Subtitles'
        # This is important! No upload nor TransPipe link on item creation!
        expect(page).to have_no_selector('.xui-upload[data-id="video_subtitles"]')
        expect(page).to have_no_link 'Manage subtitles in TransPipe'
      end

      # Stub all file upload related requests.
      (upload_ids = []) << [page.find("input[name='video[slides_upload_id]']", visible: false).value,
                            'slides.pdf', 'video_slides']
      upload_ids << [page.find("input[name='video[transcript_upload_id]']", visible: false).value,
                     'transcript.pdf', 'video_transcript']
      upload_ids << [page.find("input[name='video[reading_material_upload_id]']", visible: false).value,
                     'reading_materials.pdf', 'video_material']
      upload_ids.each do |upload_id, filename, purpose|
        stub_file_upload(upload_id:, filename:, purpose:, bucket: 'xikolo-video/videos')
      end

      click_on 'Create Item'

      Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
        .to_return Stub.json([new_item_resource])

      expect(page).to have_content new_item.title
      expect(create_item_request).to have_been_requested
      expect(new_video).to be_persisted
      expect(new_item).to be_persisted
    end
  end
end
