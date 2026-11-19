# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Show Teacher', type: :system do
  context 'when the user visits the teacher show page' do
    let(:user) { create(:'account_service/user', :admin) }
    let(:course) { create(:'course_service/course', teacher_ids: [teacher.id], title: 'Course Title') }
    let(:teacher) do
      create(:'course_service/teacher',
        picture_uri: 's3://example.com/picture.jpg',
        description: {de: 'German description', en: 'English description'})
    end

    before do
      teacher
      course
      sign_in(user:)

      click_on('Administration')
      click_on('Teacher')
      find('tr', text: teacher.name).click_on('Details')
    end

    it 'displays information about the teacher and a link to the referenced course' do
      expect(page).to have_css("img[alt='#{teacher.name}']")
      expect(page).to have_text('German description')
      expect(page).to have_text('English description')
      expect(page).to have_text(teacher.name)
      expect(page).to have_link('Edit')
      expect(page).to have_text('Course references')
      expect(page).to have_link('Course Title')

      click_on('Course Title')
      expect(page).to have_text('Edit course')

      within_fieldset('Teachers') do
        expect(page).to have_text(teacher.name)
      end
    end
  end
end
