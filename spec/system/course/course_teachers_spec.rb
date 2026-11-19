# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Teachers', type: :system do
  let(:user) { create(:'account_service/user') }
  let!(:course) do
    create(:'course_service/course', :active, teacher_ids: teachers.map {|name| create(:teacher, name:).id })
  end

  before { sign_in(user:) }

  context 'with more teachers than fit on one page' do
    let(:teachers) { ['Ada Lovelace', 'Grace Hopper', 'Alan Turing', 'Edsger Dijkstra'] }

    it 'pages through the teachers' do
      visit course_path(course.course_code)

      within('[role="region"][aria-label="Our teachers"]') do
        expect(page).to have_text 'Ada Lovelace'
        expect(page).to have_css 'button[aria-label="Previous"]:disabled'

        find('button[aria-label="Next"]').click

        expect(page).to have_css 'button[aria-label="Next"]:disabled'
        expect(page).to have_css 'button[aria-label="Previous"]:enabled'
        expect(page).to have_text 'Edsger Dijkstra'

        find('button[aria-label="Previous"]').click

        expect(page).to have_css 'button[aria-label="Previous"]:disabled'
        expect(page).to have_css 'button[aria-label="Next"]:enabled'
      end
    end

    it 'collapses an expanded description once it is paged out of view' do
      CourseService::Teacher.find_by!(name: 'Ada Lovelace')
        .update!(description: {en: 'Ada wrote the first computer program. ' * 30})

      visit course_path(course.course_code)

      within('[role="region"][aria-label="Our teachers"]') do
        click_on 'more'
        expect(page).to have_css 'button[aria-expanded="true"]', text: 'less'

        find('button[aria-label="Next"]').click
        expect(page).to have_css 'button[aria-label="Next"]:disabled'

        find('button[aria-label="Previous"]').click
        expect(page).to have_css 'button[aria-expanded="false"]', text: 'more'
      end
    end
  end

  context 'with teachers fitting on one page' do
    let(:teachers) { ['Ada Lovelace', 'Grace Hopper'] }

    it 'shows the teachers without navigation' do
      visit course_path(course.course_code)

      expect(page).to have_text 'Our teachers'
      expect(page).to have_text 'Ada Lovelace'
      expect(page).to have_text 'Grace Hopper'
      expect(page).to have_no_css 'button[aria-label="Next"]'
    end
  end

  context 'without teachers' do
    let(:teachers) { [] }

    it 'does not show the section' do
      visit course_path(course.course_code)

      expect(page).to have_text 'Course information'
      expect(page).to have_no_text 'Our teachers'
    end
  end
end
