# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Short', type: :system do
  let(:course)  { create(:course, title: 'Test Course') }
  let(:short) { create(:'course_service/short', course_id: course.id, status: 'active') }
  let(:course_2) { create(:course, title: 'Test Course two') }

  before do
    course
    short
    course_2
    sign_in(user: create(:'account_service/user', :admin))

    click_on('Administration')
    click_on('Shorts')
    click_on('Edit')
  end

  it 'prefills the form with processable short data' do
    expect(short.course_id).to eq(course.id)
    expect(short.status).to eq('active')
    expect(short.title_en).to eq('Short EN')
    expect(short.title_de).to eq('Short DE')
    expect(short.description_en).to eq('Short description EN')
    expect(short.description_de).to eq('Short description DE')

    select 'Test Course two', from: 'Course'
    select 'Preparation', from: 'Status'

    fill_in 'Title de', with: 'German short title'
    fill_in 'Title en', with: 'English short title'
    click_on 'Update short'

    expect(page).to have_text 'The short has been updated.'

    visit 'admin/shorts'

    expect(page).to have_text 'English short title'
    expect(page).to have_text 'Test Course two'
  end
end
