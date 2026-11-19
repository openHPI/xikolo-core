# frozen_string_literal: true

require 'spec_helper'

describe 'Choose alternative section within a course', type: :system do
  include ActiveJob::TestHelper

  let(:course) { create(:'course_service/course', :active) }
  let(:parent_section) { create(:'course_service/section', :parent, course: course, title: 'Parent Section', description: 'In this section you can choose between several alternatives') }
  let!(:child_section1) { create(:'course_service/section', :child, parent: parent_section, course: course, position: 1, title: 'Alternative Section 1', description: 'This is the first alternative you can choose') }
  let!(:child_section2) { create(:'course_service/section', :child, parent: parent_section, course: course, position: 2, title: 'Alternative Section 2', description: 'This is the second alternative you can choose') }

  let(:quiz1) { create(:'quiz_service/quiz', instructions: 'This is the unique text of alternative item 1', allowed_attempts: 2) }
  let!(:item1) { create(:'course_service/item', section: child_section1, content_id: quiz1.id, content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 30, title: 'Alternative Item 1') }

  let(:quiz2) { create(:'quiz_service/quiz', instructions: 'This is the unique text of alternative item 2', allowed_attempts: 2) }
  let!(:item2) { create(:'course_service/item', section: child_section2, content_id: quiz2.id, content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 30, title: 'Alternative Item 2') }

  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user: user)
    enroll_in(course)
    visit "/learn/#{course.course_code}/sections/#{parent_section.id}"
  end

  def within_section_navigation(&)
    find('.x-drawer-button').click
    within(".x-drawer-side > div[aria-label='Toggle navigation']", &)
  end

  it 'views decisions for alternative sections' do
    expect(page).to have_text(child_section1.title)
    expect(page).to have_text(child_section1.description)
    expect(page).to have_text(child_section2.title)
    expect(page).to have_text(child_section2.description)
  end

  it 'selects an alternative section' do
    click_on 'Select', match: :first

    expect(page).to have_css('h1', text: item1.title)

    expect(page).to have_text(child_section1.title)
    expect(page).to have_no_text(child_section2.title)
  end

  it 'views progress with an alternative section' do
    click_on 'Select', match: :first

    visit "/learn/#{course.course_code}/progress"

    expect(page).to have_text(child_section1.title)
    expect(page).to have_no_text(child_section2.title)
  end

  it 'selects two alternative sections' do
    click_on 'Select', match: :first

    within_section_navigation { click_on 'Parent Section' }
    click_on 'Select'

    expect(page).to have_css('h1', text: item2.title)

    within_section_navigation do
      expect(page).to have_text(child_section1.title)
      expect(page).to have_text(child_section2.title)
    end
  end

  it 'views progress with two alternative sections' do
    click_on 'Select', match: :first

    perform_enqueued_jobs do
      click_on 'quiz_submit_button'
      expect(page).to have_text(/submitted/i)
    end

    within('nav.x-breadcrumbs') { click_on 'Learnings' }
    within_section_navigation { click_on 'Parent Section' }
    click_on 'Select'

    perform_enqueued_jobs do
      click_on 'quiz_submit_button'
      expect(page).to have_text(/submitted/i)
    end

    visit "/learn/#{course.course_code}/progress"

    expect(page).to have_text(child_section1.title)
    expect(page).to have_text(child_section2.title)

    within('section[aria-labelledby="progress-header-title"]') do
      expect(page).to have_text '1 / 1'
    end
  end
end
