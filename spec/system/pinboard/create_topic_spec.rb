# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Create Topic', type: :system do
  around(&With(:csrf_protection, true))

  let(:user) { create(:'account_service/user', :gdpr_admin) }
  let(:course) { create(:'course_service/course', :active) }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: user.id) }

  before do
    sign_in(user: user)
    enroll_in(course)
  end

  it 'creates a question resource in the pinboard service' do
    visit "/learn/#{course.course_code}/pinboard"

    click_on 'Start a new topic'

    fill_in 'Title', with: 'I have a question'
    fill_markdown_editor 'Text', with: 'Where can I learn?'

    click_on 'Post new topic'

    within '#pinboard__content' do
      expect(page).to have_text 'I have a question'
    end

    expect(PinboardService::Question.count).to eq(1)
  end

  describe 'protection from accidental posts when masquerading' do
    let(:other_user) { create(:'account_service/user') }

    def open_pinboard
      visit "/learn/#{course.course_code}/pinboard"
      click_on 'Start a new topic'
      fill_in 'Title', with: 'I have a question'
      fill_markdown_editor 'Text', with: 'Where can I learn?'
    end

    it 'prevents accidental submissions of admin posts as the masqueraded user' do
      open_pinboard

      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user.id}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_text 'My upcoming learning opportunities'
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'

      expect(page).to have_text 'Did you change your account between opening and submitting this form?'
    ensure
      masquerade_window&.close
    end

    it 'prevents accidental submissions of masqueraded user posts as the admin' do
      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user.id}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_text 'My upcoming learning opportunities'
      end

      enroll_in(course)

      # Now we are the masqueraded user - prepare a post as that user
      open_pinboard

      # Then de-masquerade in the other tab
      within_window masquerade_window do
        visit current_path # Refresh the page for stubbed permissions to take effect
        click_on 'DEMASQ'
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'

      # This feature seems to not work reliable with new browser versions. Posting by mistake is not ruled out.
      if page.has_content?('Did you change your account between opening and submitting this form?') || page.has_content?('Invalid or missing CSRF token')
        expect(PinboardService::Question.count).to eq(0)
      else
        expect(PinboardService::Question.count).to eq(1)
      end
    ensure
      masquerade_window&.close
    end

    it 'still allows submissions of previously prepared posts after demasquerading' do
      open_pinboard

      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user.id}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_text 'My upcoming learning opportunities'

        # And immediately de-masquerade again
        visit current_path # Refresh the page for stubbed permissions to take effect
        click_on 'DEMASQ'
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'
      expect(page).to have_text('I have a question')

      expect(PinboardService::Question.count).to eq(1)
    ensure
      masquerade_window&.close
    end
  end
end
