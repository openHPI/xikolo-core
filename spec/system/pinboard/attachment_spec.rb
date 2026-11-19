# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Attachment Specs', type: :system do
  let(:course) { create(:'course_service/course', :active) }

  before do
    sign_in
    enroll_in(course)
  end

  it 'displays error message when select unacceptable attachments for question' do
    click_on 'Forum'

    click_on 'Start a new topic'

    attach_file 'Attachment', Rails.root.join('app/assets/fonts/OpenSansRegular.woff')

    expect(page).to have_text 'is not a valid document file'
  end

  it 'displays error message when select unacceptable attachments for answer' do
    question = create(:'pinboard_service/question', course_id: course.id, updated_at: 1.day.ago)

    visit "/learn/#{course.course_code}/question/#{question.id}"

    attach_file 'Attachment', Rails.root.join('app/assets/fonts/OpenSansRegular.woff'), id: 'xikolo_pinboard_answer_attachment'

    expect(page).to have_text 'is not a valid document file'
  end
end
