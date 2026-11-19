# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Upload a short video', type: :system do
  let(:video) { Rails.root.join('spec/support/files/video-sd.mp4').to_s }

  before do
    create(:course, title: 'Test Course')
    sign_in(user: create(:'account_service/user', :admin))

    visit '/admin/shorts/new'
  end

  it 'lists the picked file and lets it be removed again' do
    expect(page).to have_text 'Upload video'
    expect(page).to have_no_text 'Selected files'

    attach_file 'Select video', video

    expect(page).to have_text 'Selected files'
    expect(page).to have_text 'video-sd.mp4'

    find("[aria-label='Remove file']").click

    expect(page).to have_no_text 'Selected files'
    expect(page).to have_no_text 'video-sd.mp4'
  end

  it 'direct uploads the attached video on submit' do
    select 'Test Course', from: 'Course'
    fill_in 'Title en', with: 'English short title'
    attach_file 'Select video', video

    click_on 'Add short'

    expect(page).to have_text 'The short has been created.'
    expect(CourseService::Short.last.video).to be_attached
  end
end
