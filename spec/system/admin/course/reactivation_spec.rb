# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Course Reactivation', type: :system do
  let(:user) { create(:'account_service/user', :admin) }
  let(:course) { create(:course, :self_paced) }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'allows a course admin to toggle course reactivation' do
    visit edit_course_path(course)

    within_fieldset 'Certificates' do
      find('label', text: 'Reactivation').click
    end

    click_on 'Update course'

    expect(page).to have_text 'The course has been updated.'
    expect(page).to have_text 'Reactivate this course'
  end
end
