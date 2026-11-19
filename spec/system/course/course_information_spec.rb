# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Information', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:illustration_url) { ActionController::Base.helpers.asset_path('defaults/course.png') }
  let(:course) do
    create(:'course_service/course', :active, description: <<~MARKDOWN)
      Learn **Ruby** at your own pace.

      [Course website](https://example.com/course)

      ![Course illustration](#{illustration_url})

      | Topic | Level |
      | --- | --- |
      | Ruby | Beginner |
    MARKDOWN
  end

  before { sign_in(user:) }

  it 'shows the Markdown description in the first section expanded by default' do
    visit course_path(course.course_code)

    information = first('details')
    expect(information).to have_css 'summary', text: 'Course information'
    expect(information[:open]).to be_present

    within(information) do
      expect(page).to have_text 'Learn Ruby at your own pace.'
      expect(page).to have_css 'strong', text: 'Ruby'
      expect(page).to have_link 'Course website', href: 'https://example.com/course'
      expect(page).to have_css 'img[alt="Course illustration"]'
      expect(page).to have_css 'table td', text: 'Beginner'

      find('summary').click
      expect(page).to have_no_text 'Learn Ruby at your own pace.'

      find('summary').click
      expect(page).to have_text 'Learn Ruby at your own pace.'
    end
  end

  it 'shows the overview, current enrollment total, and enrollment action' do
    course.update!(enrollment_delta: 500)

    visit course_path(course.course_code)

    within('[data-testid="course-details-card"]') do
      expect(page).to have_text course.title
      expect(page).to have_text '500 enrollments'
      expect(page).to have_link 'Enroll now'
    end
  end

  context 'with learning goals' do
    before do
      course.update!(learning_goals: ['Write Ruby programs.', 'Test your code.'])
    end

    it 'shows the goals in a collapsible section after the course information' do
      visit course_path(course.course_code)

      information, goals = all('details').first(2)
      expect(goals).to have_css 'summary', text: 'Learning goals'
      expect(goals).to match_selector 'details:not([open])'

      within(goals) do
        expect(page).to have_no_text 'Write Ruby programs.'
        find('summary').click
        expect(page).to have_css 'li', text: 'Write Ruby programs.'
        expect(page).to have_css 'li', text: 'Test your code.'
        expect(page).to have_css 'ul[lang="en"]'

        find('summary').click
        expect(page).to have_no_text 'Write Ruby programs.'
      end

      expect(information).to match_selector 'details:not([open])'
    end
  end

  context 'without learning goals' do
    it 'omits the learning goals section' do
      visit course_path(course.course_code)

      expect(page).to have_css 'summary', text: 'Course information'
      expect(page).to have_no_css 'summary', text: 'Learning goals'
    end
  end

  it 'shows certificate requirements in a collapsed accordion section' do
    course.update!(roa_enabled: true, cop_enabled: true, roa_threshold_percentage: 50, cop_threshold_percentage: 70)
    visit course_path(course.course_code)

    requirements = find('details', text: 'Requirements for Proofs of Achievement')
    expect(requirements).to match_css('details:not([open])')
    expect(page).to have_no_text 'You will receive your official openHPI Certificate'

    within(requirements) do
      find('summary').click

      expect(page).to have_text 'You will receive your official openHPI Certificate by earning at least 50%'
      expect(page).to have_text 'You will automatically receive a free Confirmation of Participation once you have completed at least 70%'
      expect(page).to have_link 'Proofs of Achievement and Guidelines', href: '/pages/certificates_and_guidelines'

      find('summary').click
      expect(page).to have_no_text 'You will receive your official openHPI Certificate'
    end
  end

  context 'without certificates' do
    before { course.update!(roa_enabled: false, cop_enabled: false) }

    it 'does not show a certificate requirements section' do
      visit course_path(course.course_code)

      expect(page).to have_css 'summary', text: 'Course information'
      expect(page).to have_no_css 'summary', text: 'Requirements for Proofs of Achievement'
    end
  end
end
