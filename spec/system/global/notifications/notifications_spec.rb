# frozen_string_literal: true

require 'spec_helper'

describe 'Global/Notifications: Disable email notifications', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:subscriber) { create(:'account_service/user') }
  let(:poster) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: subscriber.id) }

  before do
    sign_in(user: poster)
    enroll_in(course)
  end

  context 'with default setting' do
    before do
      subscriber.update!(preferences: subscriber.preferences.merge(
        'notification.email.global' => true
      ))
      create(:'course_service/enrollment', course: course, user_id: subscriber.id)
      create(:'pinboard_service/subscription', question: question, user_id: subscriber.id)
    end

    it 'sends email notification when subscribed to topic and receiving reply' do
      click_on('Forum')
      click_on(question.title)

      fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'New reply'

      perform_enqueued_jobs do
        click_on 'Post reply'
        within('.qa-box.answer') do
          expect(page).to have_text('New reply')
        end
      end

      expect(find_mail_to(subscriber.email)).to be_present
    end
  end

  context 'when disabling notifications' do
    it 'does not receive email after disabling notifications' do
      subscriber.update!(preferences: subscriber.preferences.merge(
        'notification.email.global' => false
      ))
      create(:'course_service/enrollment', course: course, user_id: subscriber.id)
      create(:'pinboard_service/subscription', question: question, user_id: subscriber.id)

      click_on('Forum')
      click_on(question.title)

      fill_markdown_editor '#markdown-input-text-answer-', use_selector: true, with: 'New reply'

      perform_enqueued_jobs do
        click_on 'Post reply'
        within('.qa-box.answer') do
          expect(page).to have_text('New reply')
        end
      end

      expect(find_mail_to(subscriber.email)).to be_nil
    end
  end
end
