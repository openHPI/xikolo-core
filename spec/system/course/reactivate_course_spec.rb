# frozen_string_literal: true

require 'spec_helper'

describe 'Reactivate a course', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) do
    create(:'course_service/course',
      published: true,
      on_demand: true,
      roa_enabled: true,
      start_date: 10.weeks.ago,
      end_date: 3.weeks.ago)
  end
  let(:section) { create(:'course_service/section', course: course, start_date: 4.weeks.ago) }
  let(:quiz) { create(:'quiz_service/quiz', allowed_attempts: 2) }
  let!(:item) do
    create(:'course_service/item', :homework,
      section: section,
      submission_deadline: 2.days.ago,
      max_dpoints: 10,
      content_type: 'quiz',
      content_id: quiz.id)
  end
  let!(:voucher) { create(:voucher, :reactivation) }

  before do
    create(:'quiz_service/free_text_question', quiz: quiz, points: 10.0)
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    sign_in(user: user)
  end

  context 'Enrolled learner can reactivate with voucher' do
    before do
      enroll_in(course)
    end

    it 'reactivates the course' do
      expect(page).to have_text 'Reactivate this course'

      click_on 'Reactivate this course'

      expect(page).to have_text 'Once you redeem the code, you will have 8 weeks'

      fill_in 'Enter your voucher code', with: voucher.id

      click_on 'Redeem'

      expect(page).to have_text 'You have reactivated this course until'
      expect(page).to have_no_text 'Reactivate this course'
    end
  end

  context 'Enrolled learner can access graded assignment after reactivation' do
    before do
      create(:'course_service/enrollment', course: course, user_id: user.id)

      # Reactivate course first
      visit course_path(course.course_code)
      click_on 'Reactivate this course'
      fill_in 'Enter your voucher code', with: voucher.id
      click_on 'Redeem'
      expect(page).to have_text 'You have reactivated this course until'
    end

    it 'allows access to the quiz' do
      visit course_item_path(course, section, item)

      # Wait, course reactivation shifts the item deadline conceptually.
      # "Due on [8 weeks from now]"
      expect(page).to have_text "Due on #{8.weeks.from_now.strftime('%B %d, %Y')}"

      click_on 'Start quiz now'

      # Confirm popup
      click_on 'Yes, sure'

      # Verify quiz started
      expect(page).to have_text('Send my final answers')
    end
  end
end
