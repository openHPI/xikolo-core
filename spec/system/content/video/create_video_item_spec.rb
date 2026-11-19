# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Create video item', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:user) { create(:'account_service/user') }

  before do
    section

    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)

    sign_in(user:)
    enroll_in(course)
  end

  context 'on the course sections page' do
    before do
      click_on 'Course Administration'
      click_on 'Structure & Content'
    end

    it 'specifies an item to be of type video' do
      click_on 'Add item'
      select 'Video', from: 'Type'

      expect(page).to have_text 'Description'
      expect(page).to have_text 'Pip stream'
      expect(page).to have_text 'Lecturer stream'
      expect(page).to have_text 'Slides stream'
      expect(page).to have_text 'Subtitles'
      expect(page).to have_text 'Slides'
      expect(page).to have_text 'Transcript'
      expect(page).to have_text 'Reading material'
    end

    context 'with available streams' do
      before do
        create(:stream, title: "#{course.course_code}_pip")
        create(:stream, title: "#{course.course_code}_lecturer")
        create(:stream, title: "#{course.course_code}_slides")
      end

      it 'creates a video with minimal information' do
        click_on 'Add item'
        select 'Video', from: 'Type'

        fill_in 'Title', with: 'New Video Title'
        fill_markdown_editor 'Description', with: 'A **USELESS** but highlighted description!'
        tom_select '_pip', from: 'Pip stream', search: true
        tom_select '_lecturer', from: 'Lecturer stream', search: true
        tom_select '_slides', from: 'Slides stream', search: true

        click_on 'Create Item'

        expect(page).to have_current_path("/learn/#{course.course_code}/sections")
        expect(page).to have_text 'New Video Title'
      end

      it 'creates a video with downloadable content' do
        click_on 'Add item'
        select 'Video', from: 'Type'

        fill_in 'Title', with: 'New Video Title'
        fill_markdown_editor 'Description', with: 'A **USELESS** but highlighted description!'
        tom_select '_pip', from: 'Pip stream', search: true
        tom_select '_lecturer', from: 'Lecturer stream', search: true
        tom_select '_slides', from: 'Slides stream', search: true

        # Stub file uploads before attaching
        upload_ids = []
        upload_ids << [page.find("input[name='video_video[slides_upload_id]']", visible: false).value,
                       'www_slides.pdf', 'video_slides']
        upload_ids << [page.find("input[name='video_video[transcript_upload_id]']", visible: false).value,
                       'www_slides.pdf', 'video_transcript']
        upload_ids << [page.find("input[name='video_video[reading_material_upload_id]']", visible: false).value,
                       'www_slides.pdf', 'video_material']
        upload_ids.each do |upload_id, filename, purpose|
          stub_file_upload(upload_id:, filename:, purpose:, bucket: 'xikolo-video/videos')
        end

        attach_file 'Slides', './spec/fixtures/files/www_slides.pdf'
        attach_file 'Transcript', './spec/fixtures/files/www_slides.pdf'
        attach_file 'Reading material', './spec/fixtures/files/www_slides.pdf'

        click_on 'Create Item'

        expect(page).to have_current_path("/learn/#{course.course_code}/sections")
        expect(page).to have_text 'New Video Title'
      end
    end
  end

  context 'when a video item with downloadable content was created' do
    let(:video) { create(:video, :with_attachments) }

    before do
      create(:'course_service/item', section:, content: video, exercise_type: 'video')
    end

    it 'shows download cards for all content' do
      within '[data-testid="course-details-card"]' do
        click_on 'Continue course'
      end

      expect(page).to have_text 'Video (HD) as MP4'
      expect(page).to have_text 'Video (SD) as MP4'
      expect(page).to have_text 'Presentation slides as PDF'
      expect(page).to have_text 'Transcription'
      expect(page).to have_text 'Reading material'
    end
  end
end
