# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Delete Teacher', type: :system do
  let(:user) { create(:'account_service/user', :gdpr_admin) }

  before do
    sign_in(user:)
  end

  context 'when the teacher is not referenced in any course' do
    let!(:teacher) { create(:'course_service/teacher') }

    it 'deletes the teacher and shows a success message' do
      visit '/teachers'

      find('tr', text: teacher.name).click_on('Delete')
      click_on('Yes, sure')

      expect(page).to have_text('Teacher was deleted successfully.')
      expect(page).to have_no_text(teacher.name)
    end
  end

  context 'when the teacher is referenced in a course' do
    let!(:teacher) { create(:'course_service/teacher') }
    let(:course) do
      create(:'course_service/course', teacher_ids: [teacher.id])
    end

    it 'navigates to the teacher detail page and the teacher remains on the list' do
      course # create course with teacher reference
      visit '/teachers'

      find('tr', text: teacher.name).click_on('Delete')
      click_on('Yes, sure')

      expect(page).to have_current_path("/teachers/#{teacher.id}")

      visit '/teachers'

      expect(page).to have_text(teacher.name)
    end
  end
end
