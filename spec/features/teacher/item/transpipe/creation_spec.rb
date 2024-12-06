# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Item: TransPipe: Create Item', gen: 2, type: :feature do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let(:course) do
    build(:'course:course', course_code: 'the_course')
  end
  let(:section) do
    build(:'course:section', course_id: course['id'], title: 'Week 1')
  end
  let!(:stream) { create(:stream, title: 'the_course_pip1') }
  let(:new_video) { build(:video, pip_stream_id: stream.id) }
  let(:persisted_video) { Video::Video.create(title: new_item[:title], pip_stream_id: stream.id) }
  let(:new_item) do
    build(:'course:item', :video,
      course_id: course['id'],
      section_id: section['id'],
      content_id: new_video.id)
  end

  before do
    stub_user id: user_id, permissions: %w[course.content.access course.content.edit video.video.index]
    Stub.service(:course, build(:'course:root'))
    Stub.service(:peerassessment, build(:'peerassessment:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)
    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course['id'], user_id:}
    ).to_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course['id']}
    ).to_return Stub.json([section])
    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section['id'])
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :peerassessment, :get, '/peer_assessments',
      query: {course_id: course['id']}
    ).to_return Stub.json([])

    # Stubs for processing and the "Edit item" page shown after saving
    Stub.request(
      :pinboard, :post, '/implicit_tags',
      body: hash_including(course_id: course['id'], referenced_resource: 'Xikolo::Course::Item')
    ).to_return Stub.json({})
    Stub.request(
      :course, :get, "/items/#{new_item['id']}"
    ).to_return Stub.json(new_item)
    Stub.request(
      :course, :get, "/items/#{new_item['id']}", query: {raw: '1'}
    ).to_return Stub.json(new_item)
  end

  it 'allows subtitle uploads via the platform and does not show the TransPipe link by default' do
    visit "/courses/the_course/sections/#{section['id']}/items/new"
    expect(page).to have_content 'Create new item in section "Week 1"'

    select 'Video', from: 'Type'

    within_fieldset('Video Data') do
      expect(page).to have_content 'Subtitles'
      expect(page).to have_css('.xui-upload[data-id="video_subtitles"]')
      expect(page).to have_no_link 'Manage subtitles in TransPipe'
    end
  end

  context 'with TransPipe enabled' do
    before do
      create(:course, id: course['id'])
      xi_config <<~YML
        transpipe:
          enabled: true
          course_video_url_template: https://transpipe.example.com/link/platform/courses/{course_id}/videos/{video_id}
      YML
    end

    it 'hides the subtitle upload' do
      visit "/courses/the_course/sections/#{section['id']}/items/new"
      expect(page).to have_content 'Create new item in section "Week 1"'

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

      slides_upload_id = page.find("input[name='video[slides_upload_id]']", visible: false).value
      transcript_upload_id = page.find("input[name='video[transcript_upload_id]']", visible: false).value
      reading_material_upload_id = page.find("input[name='video[reading_material_upload_id]']", visible: false).value

      stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads/#{transcript_upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{transcript_upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
            </ListBucketResult>
          XML
      stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads/#{slides_upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{slides_upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
            </ListBucketResult>
          XML
      stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads/#{reading_material_upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{reading_material_upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
            </ListBucketResult>
          XML

      stub = Stub.request(:course, :post, '/items').to_return Stub.json(new_item)
      allow(new_video).to receive(:save!).and_return persisted_video

      click_on 'Create Item'

      expect(stub).to have_been_requested
      expect(Video::Video.last.title).to eq('Video without subtitles')
    end
  end
end
