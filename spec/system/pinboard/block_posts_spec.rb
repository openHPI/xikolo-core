# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Block a post', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }
  let(:admin) { create(:'account_service/user') }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group:)
  end

  describe 'blocking a topic directly as admin' do
    it 'blocks the topic and shows a [Blocked] badge' do
      sign_in(user: admin)

      visit "/learn/#{course.course_code}/question/#{question.id}"

      click_on 'block'

      within('.question-title') do
        expect(page).to have_text '[Blocked]'
      end
    end
  end

  describe 'blocking a topic with abuse reports' do
    it 'auto-blocks when three students report the topic' do
      sign_in(user: admin)

      3.times do |i|
        student = create(:'account_service/user')

        using_session(:"student_#{i}") do
          sign_in(user: student)
          enroll_in(course)

          visit "/learn/#{course.course_code}/question/#{question.id}"

          click_on 'report'

          within('[role=dialog][aria-modal=true]') do
            click_on 'Yes, sure'
          end

          expect(page).to have_text 'Your report was received successfully'
        end
      end

      # Verify as a random user
      stranger = create(:'account_service/user')
      Capybara.using_session(:stranger) do
        sign_in(user: stranger)
        enroll_in(course)

        visit "/learn/#{course.course_code}/question/#{question.id}"

        within('.question-title') do
          expect(page).to have_text '[Blocked]'
        end
      end
    end
  end

  describe 'sending an email when a topic is autoblocked' do
    it 'sends an email to all course admins with a link to the topic' do
      admins = Array.new(2) do
        admin_user = create(:'account_service/user')
        group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
        create(:'account_service/membership', user: admin_user, group:)
        admin_user
      end

      sign_in(user: admins.first)

      3.times do |i|
        student = create(:'account_service/user')

        Capybara.using_session(:"student_#{i}") do
          sign_in(user: student)
          enroll_in(course)

          visit "/learn/#{course.course_code}/question/#{question.id}"

          click_on 'report'

          within('[role=dialog][aria-modal=true]') do
            click_on 'Yes, sure'
          end

          expect(page).to have_text 'Your report was received successfully'
        end
      end

      perform_enqueued_jobs(only: NotificationService::SendNotificationJob)

      admins.each do |admin_user|
        mail = find_mail_to(admin_user.email)
        expect(mail.subject).to eq 'Please review blocked pinboard item'
        expect(mail.text_part.body.decoded).to include 'an item was automatically blocked. Please review!'
        expect(mail.text_part.body.decoded).to include "/courses/#{course.course_code}/question/#{question.id}"
      end
    end
  end

  describe 'authorized user can still see or answer a blocked post' do
    it 'allows admin to see content, reply, and comment after blocking' do
      create(:'pinboard_service/answer', question:, user_id: user.id)

      sign_in(user: admin)

      visit "/learn/#{course.course_code}/question/#{question.id}"

      within(first('.qa-content')) do
        click_on 'block'
      end

      expect(page).to have_text(question.text)
      expect(page).to have_button 'Add reply'
      expect(page).to have_button 'Add comment'
    end
  end

  describe 'normal user cannot see or answer a blocked post' do
    it 'prevents normal user from seeing content or interacting' do
      create(:'pinboard_service/answer', question:, user_id: user.id)

      sign_in(user: admin)

      visit "/learn/#{course.course_code}/question/#{question.id}"

      within(first('.qa-content')) do
        click_on 'block'
      end

      Capybara.using_session(:normal_user) do
        sign_in(user:)
        enroll_in(course)

        visit "/learn/#{course.course_code}/question/#{question.id}"

        expect(page).to have_text '[Blocked]'
        expect(page).to have_no_text(question.text)
        expect(page).to have_no_button 'Add reply'
        expect(page).to have_no_button 'Add comment'
      end
    end
  end
end
