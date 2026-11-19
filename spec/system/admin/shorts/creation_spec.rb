# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Short', type: :system do
  let(:course) { create(:course, title: 'Test Course') }

  before do
    course
    sign_in(user: create(:'account_service/user', :admin))

    click_on('Administration')
    click_on('Shorts')
    click_on('Create new short')
  end

  it 'prefills the form with processable short data' do
    select 'Test Course', from: 'Course'
    select 'Active', from: 'Status'

    fill_in 'Title de', with: 'German short title'
    fill_in 'Title en', with: 'English short title'
    fill_in 'Description de', with: 'German short description'
    fill_in 'Description en', with: 'English short description'

    expect(page).to have_text 'Upload video'

    click_on 'Add short'

    expect(page).to have_text 'The short has been created.'

    visit 'admin/shorts'

    expect(page).to have_text 'English short title'
    expect(page).to have_text 'Test Course'
  end
end
