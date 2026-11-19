# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Course', type: :system do
  let(:teacher_1) { create(:'course_service/teacher') }
  let(:teacher_2) { create(:'course_service/teacher') }

  before do
    sign_in(user: create(:'account_service/user', :gdpr_admin))
  end

  it 'prefills the form with processable course data' do
    visit '/learn/new'

    fill_in 'Course code', with: 'test2018'
    fill_in 'Title', with: 'Automated Testing (2018 Edition)'
    fill_markdown_editor 'Description', with: 'This is the Automated Testing (2018 Edition).'
    select 'English', from: 'Content language'

    all(:button, 'Advanced settings').map(&:click)

    tom_select teacher_1.name, from: 'Teachers'

    fill_in('Learning goals', with: 'rspec').send_keys(:return)
    fill_in('Learning goals', with: 'capybara').send_keys(:return)

    click_on 'Create course'

    expect(page).to have_text 'The course has been created.'

    course = CourseService::Course.first
    expect(CourseService::Course.count).to eq(1)
    expect(course.course_code).to eq('test2018')
    expect(course.title).to eq('Automated Testing (2018 Edition)')
    expect(course.middle_of_course).to be_nil
    expect(course.teacher_ids).to eq([teacher_1.id])

    visit course_path(course)
    expect(page).to have_text course.title
  end

  context 'with an existing course with the same course code' do
    let(:course) { create(:'course_service/course', course_code: 'test2018') }

    before do
      course
    end

    it 'does not create the course if the course code is not unique' do
      visit '/learn/new'

      fill_in 'Course code', with: 'test2018'
      fill_in 'Title', with: 'Automated Testing (2018 Edition)'
      fill_markdown_editor 'Description', with: 'This is the Automated Testing (2018 Edition).'
      select 'English', from: 'Content language'

      click_on 'Create course'

      expect(page).to have_text('We found some errors. Please review your form input.')
      expect(page).to have_text('has already been taken')
    end
  end

  it 'creates an external course' do
    visit '/learn/new'

    fill_in 'Course code', with: 'test2018-ext'
    fill_in 'Title', with: 'External Example Course Title'
    fill_markdown_editor 'Description', with: 'This is the Automated Testing.'
    select 'English', from: 'Content language'

    all(:button, 'Advanced settings').map(&:click)
    fill_in 'External course URL', with: 'https://mooc.house'

    click_on 'Create course'

    expect(page).to have_text 'The course has been created.'

    course = CourseService::Course.find_by(course_code: 'test2018-ext')
    expect(course.title).to eq('External Example Course Title')
    expect(course.external_course_url).to eq('https://mooc.house')

    # verify the "new external course page" assertions
    visit course_path(course)
    expect(page).to have_text 'External Example Course Title'
    expect(page).to have_text 'This is the Automated Testing.'
    expect(page).to have_link 'Go to external course'
  end
end
