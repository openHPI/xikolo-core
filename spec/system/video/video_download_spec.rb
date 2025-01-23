# frozen_string_literal: true

require 'spec_helper'

describe 'Video Download', type: :system do
  let(:user_id) { generate(:user_id) }
  let(:submission_id) { SecureRandom.uuid }
  let(:course) { create(:course, course_code: 'the_course') }
  let(:section) { create(:section, course:) }
  let(:item) { create(:item, section:, content: video) }
  let(:video) { create(:video, :with_attachments) }

  let(:course_params) { {id: course.id, course_code: course.course_code, context_id: course.context_id} }

  let(:course_resource) { build(:'course:course', course_params) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item_resource) do
    build(:'course:item', :video,
      id: item.id,
      course_id: course.id,
      section_id: section.id,
      content_id: video.id,
      title: item.title)
  end

  before do
    # We need two session stubs here, one for the actual course context the request is executed ...
    stub_user permissions: %w[course.content.access.available], id: user_id, context_id: course.context_id
    # ... and a second one in root context for a JS-triggered APIv2 call
    stub_user permissions: %w[course.content.access.available], id: user_id
    Stub.service(:course, build(:'course:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json({id: user_id})
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .and_return Stub.json({properties: {}})
    Stub.request(:course, :get, '/api/v2/course/courses/the_course', query: hash_including({}))
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, '/courses/the_course')
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, "/courses/#{course.id}")
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, "/enrollments?course_id=#{course.id}&user_id=#{user_id}")
      .and_return Stub.json([{}])
    Stub.request(:course, :get, "/items/#{item.id}", query: hash_including({}))
      .and_return Stub.json(item_resource)
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
      .and_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .and_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course.id))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(
      :course, :post, "/items/#{item.id}/users/#{user_id}/visit"
    ).to_return Stub.json({item_id: item.id, user_id:})

    Stub.request(:pinboard, :get, '/topics', query: {item_id: item.id})
      .to_return Stub.json([])
  end

  context 'with disabled video download' do
    let(:course_params) { super().merge(enable_video_download: false) }

    it 'shows a disabled download button for the video in SD and HD with a tooltip' do
      visit "/courses/the_course/items/#{item.id}"
      click_on 'Download video'

      hd_download_button = find_button 'Video (HD) as MP4', disabled: true
      expect(hd_download_button['title']).to have_content 'Downloading this video/audio is not possible due to licensing regulations.'

      sd_download_button = find_button 'Video (SD) as MP4', disabled: true
      expect(sd_download_button['title']).to have_content 'Downloading this video/audio is not possible due to licensing regulations.'
    end

    it 'shows a disabled download button for the audio with a tooltip' do
      visit "/courses/the_course/items/#{item.id}"
      click_on 'Download additional material'
      audio_download_button = find_button 'Audio as MP3', disabled: true

      expect(audio_download_button['title']).to have_content 'Downloading this video/audio is not possible due to licensing regulations.'
      expect(audio_download_button['class']).to have_content 'disabled'
    end

    it 'shows download buttons for the slides, the transcript and the reading material' do
      visit "/courses/the_course/items/#{item.id}"
      click_on 'Download additional material'
      dropdown_menu = find('ul[data-behaviour="menu-dropdown"]')
      within dropdown_menu do
        expect(page).to have_css '[download]', count: 3
        expect(page).to have_content 'Presentation slides as PDF'
        expect(page).to have_content 'Transcription'
        expect(page).to have_content 'Reading material'
      end

      dropdown_menu.all('[download]') do |button|
        expect(button['title']).to have_no_content 'Downloading this video/audio is not possible due to licensing regulations.'
        expect(button['class']).to have_no_content 'disabled'
      end
    end
  end

  context 'with enabled video download' do
    let(:course_params) { super().merge(enable_video_download: true) }

    it 'shows video download buttons for the video in sd and hd without a tooltip' do
      visit "/courses/the_course/items/#{item.id}"
      click_on 'Download video'
      dropdown_menu = find('ul[data-behaviour="menu-dropdown"]')
      within dropdown_menu do
        expect(page).to have_css '[download]', count: 2
      end
      dropdown_menu.all('[download]') do |button|
        expect(button['title']).to have_no_content 'Downloading this video/audio is not possible due to licensing regulations.'
        expect(button['class']).to have_no_content 'disabled'
      end
    end

    it 'shows additional download buttons for the audio, the slides, the transcript and the reading material without a tooltip' do
      visit "/courses/the_course/items/#{item.id}"
      click_on 'Download additional material'
      dropdown_menu = find('ul[data-behaviour="menu-dropdown"]')
      within dropdown_menu do
        expect(page).to have_css '[download]', count: 4
      end
      dropdown_menu.all('[download]') do |button|
        expect(button['title']).to have_no_content 'Downloading this video/audio is not possible due to licensing regulations.'
        expect(button['class']).to have_no_content 'disabled'
      end
    end
  end
end
