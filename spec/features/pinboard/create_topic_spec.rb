# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Create Topic', gen: 2, type: :feature do
  before do
    stub_user permissions: user_permissions, id: user['id']
    Stub.service(:course, build(:'course:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:account, :get, "/users/#{user['id']}")
      .and_return Stub.json(user)
    Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/courses/our_course')
      .and_return Stub.json(course)
    Stub.request(:course, :get, "/courses/#{course['id']}")
      .and_return Stub.json(course)
    Stub.request(:course, :get, '/api/v2/course/courses/our_course', query: hash_including({}))
      .and_return Stub.json(course)
    Stub.request(:course, :get, "/enrollments?course_id=#{course['id']}&user_id=#{user['id']}")
      .and_return Stub.json([{}])
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course['id']))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/items', query: hash_including(course_id: course['id']))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/questions', query: hash_including(course_id: course['id']))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/tags', query: hash_including(course_id: course['id']))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/explicit_tags', query: hash_including(course_id: course['id']))
      .to_return Stub.json([])
  end

  around(&With(:csrf_protection, true))

  let(:user) { build(:'account:user') }
  let(:user_permissions) { %w[course.content.access.available account.user.masquerade] }
  let(:course) do
    build(:'course:course',
      course_code: 'our_course',
      title: 'Automated Testing (2018 Edition)')
  end
  let!(:create_question) do
    Stub.request(:pinboard, :post, '/questions')
      .to_return Stub.response(status: 201)
  end

  it 'creates a question resource in the pinboard service' do
    visit '/courses/our_course/pinboard'

    click_on 'Start a new topic'

    fill_in 'Title', with: 'I have a question'
    fill_markdown_editor 'Text', with: 'Where can I learn?'

    click_on 'Post new topic'

    # There is no stub for actual content after creation, so the page
    # stays empty even after "a question has been created".
    # Nevertheless, we must wait for the page to be there again.
    #
    # Otherwise the test would immediately continue checking the stub,
    # even if the actual request is still processed and might not have
    # called the stub yet.
    expect(page).to have_content 'Sorry, nothing here yet.'

    expect(
      create_question.with(
        body: hash_including(
          'title' => 'I have a question',
          'text' => 'Where can I learn?'
        )
      )
    ).to have_been_requested
  end

  describe 'protection from accidental posts when masquerading' do
    let(:other_user) { build(:'account:user') }
    let(:other_permissions) { %w[course.content.access.available] }

    before do
      Stub.request(:course, :get, '/courses', query: hash_including({}))
        .and_return Stub.json([])
      Stub.request(:course, :get, '/enrollments', query: hash_including({}))
        .and_return Stub.json([])
      Stub.request(:course, :get, '/teachers', query: {user_id: other_user['id']})
        .and_return Stub.json([])
      Stub.request(:account, :get, "/users/#{other_user['id']}")
        .and_return Stub.json(other_user)
      Stub.request(:account, :get, "/sessions/#{stub_session_id}")
        .and_return Stub.json({masquerade_url: "/sessions/#{stub_session_id}/masquerade"})
      Stub.request(:account, :post, "/sessions/#{stub_session_id}/masquerade")
        .and_return Stub.response(status: 201)
      Stub.request(:account, :delete, "/sessions/#{stub_session_id}/masquerade")
        .and_return Stub.response(status: 200)
      Stub.request(:account, :post, '/tokens')
        .and_return Stub.response(status: 201)
    end

    it 'prevents accidental submissions of admin posts as the masqueraded user' do
      pending 'Multi-window browser spec fail in CI'

      visit '/courses/our_course/pinboard'
      click_on 'Start a new topic'
      fill_in 'Title', with: 'I have a question'
      fill_markdown_editor 'Text', with: 'Where can I learn?'

      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user['id']}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_content 'My upcoming courses'
        stub_user_request permissions: other_permissions, id: other_user['id'], masqueraded: true
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'

      expect(page).to have_content 'Did you change your account between opening and submitting this form?'
      expect(create_question).not_to have_been_requested
    ensure
      masquerade_window&.close
    end

    it 'prevents accidental submissions of masqueraded user posts as the admin' do
      pending 'Multi-window browser spec fail in CI'

      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user['id']}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_content 'My upcoming courses'
        stub_user_request permissions: other_permissions, id: other_user['id'], masqueraded: true
      end

      # Now we are the masqueraded user - prepare a post as that user
      visit '/courses/our_course/pinboard'
      click_on 'Start a new topic'
      fill_in 'Title', with: 'I have a question'
      fill_markdown_editor 'Text', with: 'Where can I learn?'

      # Then de-masquerade in the other tab
      within_window masquerade_window do
        visit current_path # Refresh the page for stubbed permissions to take effect
        click_on 'DEMASQ'
        stub_user_request permissions: user_permissions, id: user['id']
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'

      expect(page).to have_content 'Did you change your account between opening and submitting this form?'
      expect(create_question).not_to have_been_requested
    ensure
      masquerade_window&.close
    end

    it 'still allows submissions of previously prepared posts after demasquerading' do
      pending 'Multi-window browser spec fail in CI'

      visit '/courses/our_course/pinboard'
      click_on 'Start a new topic'
      fill_in 'Title', with: 'I have a question'
      fill_markdown_editor 'Text', with: 'Where can I learn?'

      # In a separate tab, masquerade as another user
      masquerade_window = open_new_window
      within_window masquerade_window do
        visit "/users/#{other_user['id']}"
        click_on 'Masquerade as user'
        # When masquerading, expect to be redirected to the user's dashboard.
        expect(page).to have_content 'My upcoming courses'
        stub_user_request permissions: other_permissions, id: other_user['id'], masqueraded: true

        # And immediately de-masquerade again
        visit current_path # Refresh the page for stubbed permissions to take effect
        click_on 'DEMASQ'
        stub_user_request permissions: user_permissions, id: user['id']
      end

      # Try to submit the forum post in the original tab
      click_on 'Post new topic'

      # There is no stub for actual content after creation, so the page
      # stays empty even after "a question has been created".
      # Nevertheless, we must wait for the page to be there again.
      #
      # Otherwise the test would immediately continue checking the stub,
      # even if the actual request is still processed and might not have
      # called the stub yet.
      expect(page).to have_content 'Sorry, nothing here yet.'

      expect(
        create_question.with(
          body: hash_including(
            'title' => 'I have a question',
            'text' => 'Where can I learn?'
          )
        )
      ).to have_been_requested
    ensure
      masquerade_window&.close
    end
  end
end
