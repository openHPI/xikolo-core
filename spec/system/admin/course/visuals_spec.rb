# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Course Visuals', type: :system do
  let(:course) { create(:'course_service/course', :active, course_code: 'the_course') }
  let(:user) { create(:'account_service/user', :admin) }

  before do
    sign_in(user:)
  end

  it 'adds a visual to the course' do
    visit edit_course_visual_path(course)

    attach_file 'Image', './spec/fixtures/files/redsandsforts.jpg'
    click_on 'Save and show course'

    expect(page).to have_current_path(course_path(id: course.course_code))
    expect(page).to have_xpath("//img[contains(@src, 'redsandsforts.jpg')]")
  end

  it 'creates a course with video' do
    create(:'account_service/feature', name: 'vimeo_player', owner: user)
    create(:stream, title: 'the_course_internetworking_intro_pip')

    visit edit_course_visual_path(course)

    tom_select '_internetworking_intro_pip', from: 'Teaser video', search: true
    click_on 'Save and show course'

    expect(page).to have_current_path(course_path(id: course.course_code))
    expect(page).to have_xpath('//xm-player[contains(@class, "hydrated")]')
  end

  it 'uploads a Bunny teaser and displays it below the course content' do
    create_double = instance_double(CreateVideoOnBunny, call: 'bunny-teaser')
    upload_double = instance_double(UploadVideoOnBunny, call: nil)
    allow(CreateVideoOnBunny).to receive(:new).and_return(create_double)
    allow(UploadVideoOnBunny).to receive(:new).and_return(upload_double)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_LIBRARY_ID').and_return('library')

    visit edit_course_visual_path(course)
    attach_file 'Select video', Rails.root.join('spec/support/files/video-sd.mp4')
    click_on 'Save', exact: true

    expect(page).to have_text 'Video upload: Waiting'
    stream = course.reload.visual.video_stream
    expect(stream.video).to be_attached
    expect(stream.provider.provider_type).to eq 'bunny'
    expect(enqueued_jobs.find {|job| job[:job] == UploadStreamToBunnyJob }[:args]).to eq [stream.id]

    UploadStreamToBunnyJob.perform_now(stream.id)
    visit course_path(course)

    within 'section[aria-labelledby="course-teaser-title"]' do
      expect(page).to have_text 'Watch the teaser for this online course'
      expect(page).to have_css('video-player video-skin hlsjs-video')
      expect(page).to have_css('hlsjs-video[src$="/learn/the_course/teaser_signed_url"]')
    end
    within '[data-testid="course-details-card"]' do
      expect(page).to have_css('img')
      expect(page).to have_no_css('video-player')
    end

    visit edit_course_visual_path(course)
    find(:label, text: 'Teaser video', exact_text: true).find(:xpath, '..').find('.clear-button', visible: :all).click
    click_on 'Save and show course'
    expect(page).to have_no_css('section[aria-labelledby="course-teaser-title"]')
  end
end
