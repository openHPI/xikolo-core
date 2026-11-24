# frozen_string_literal: true

require 'spec_helper'

describe 'Video Download', type: :system do
  let(:user) { create('account_service/user') }
  let(:course) { create(:'course_service/course', :active, course_code: 'the_course') }
  let(:video) { create(:video, :with_attachments) }
  let(:item) { create(:'course_service/item', section:, content: video) }
  let(:section) { create(:'course_service/section', course:) }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  context 'with disabled video download' do
    before do
      course.update!(enable_video_download: false)
      visit "/learn/the_course/items/#{item.id}"
    end

    it 'hides the video and audio download cards' do
      expect(page).to have_no_text 'Video (HD) as MP4'
      expect(page).to have_no_text 'Video (SD) as MP4'
      expect(page).to have_no_text 'Audio as MP3'
    end

    it 'shows download cards for the slides, the transcript and the reading material' do
      expect(page).to have_text 'Presentation slides as PDF'
      expect(page).to have_text 'Transcription'
      expect(page).to have_text 'Reading material'
    end
  end

  context 'with enabled video download' do
    before do
      course.update!(enable_video_download: true)
      visit "/learn/the_course/items/#{item.id}"
    end

    it 'shows download cards for the video in sd and hd' do
      expect(page).to have_text 'Video (HD) as MP4'
      expect(page).to have_text 'Video (SD) as MP4'
    end

    it 'shows download cards for the audio, the slides, the transcript and the reading material' do
      expect(page).to have_text 'Audio as MP3'
      expect(page).to have_text 'Presentation slides as PDF'
      expect(page).to have_text 'Transcription'
      expect(page).to have_text 'Reading material'
    end
  end
end
