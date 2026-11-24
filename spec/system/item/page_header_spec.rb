# frozen_string_literal: true

require 'spec_helper'

describe 'Item: Page Header', type: :system do
  let(:course) { create(:'course_service/course', :active, title: 'Digitale Gerechtigkeit') }
  let(:section) { create(:'course_service/section', course:, title: 'Modul 1') }
  let(:richtext) { create(:'course_service/richtext', course:) }
  let!(:item) do
    create(
      :'course_service/item',
      section:,
      title: 'Was ist digitale Gerechtigkeit?',
      content: richtext,
      open_mode: true
    )
  end

  let(:header) { find('nav.x-breadcrumbs').ancestor('header') }

  before { visit "/learn/#{course.course_code}/items/#{item['id']}" }

  it 'shows the item inside the course header' do
    expect(header).to have_text('Digitale Gerechtigkeit')
    expect(header).to have_css('h1', text: 'Was ist digitale Gerechtigkeit?')
    expect(header).to have_text('Modul 1')
  end

  it 'leaves the page heading to the item' do
    expect(page).to have_no_css('h1', text: 'Digitale Gerechtigkeit')
  end

  it 'shows the trail leading to the item' do
    within('nav.x-breadcrumbs') do
      expect(page).to have_link(href: root_path)
      expect(page).to have_link('Learn', href: courses_path)
      expect(page).to have_link('Digitale Gerechtigkeit', href: course_path(course.course_code))
      expect(page).to have_link('Learnings', href: course_resume_path(course.course_code))
    end
  end

  it 'links back to the course details' do
    expect(header).to have_link('Back to course details', href: course_path(course.course_code))
  end

  context 'on a course page without an item' do
    let(:user) { create(:'account_service/user') }

    before do
      sign_in(user:)
      enroll_in(course)
      visit "/learn/#{course.course_code}/progress"
    end

    it 'shows the course title and no item' do
      expect(header).to have_text('Digitale Gerechtigkeit')
      expect(header).to have_no_text('Was ist digitale Gerechtigkeit?')
    end

    it 'ends the trail at the page the user is on' do
      within('nav.x-breadcrumbs') { expect(page).to have_text('Progress') }
    end

    it 'does not link back to the course details' do
      expect(header).to have_no_link('Back to course details')
    end
  end

  context 'as a course admin' do
    let(:admin) { create(:'account_service/user') }

    before do
      group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
      create(:'account_service/membership', user: admin, group:)
      sign_in(user: admin)
      visit "/learn/#{course.course_code}/items/#{item['id']}"
    end

    it 'offers the item and course admin actions in the header' do
      expect(header).to have_link('Edit item')
      expect(header).to have_link('Statistics')
      expect(header).to have_link('Go to course administration', href: course_sections_path(course.course_code))
    end
  end
end
