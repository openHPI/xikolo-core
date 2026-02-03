# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Item: Proctoring: Modify Item', type: :system do
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let(:course) do
    build(:'course:course',
      course_code: 'the_course',
      title: 'Proctored course',
      proctored: true)
  end
  let(:section) do
    build(:'course:section', course_id: course['id'], title: 'Week 1')
  end
  let(:quiz) { build(:'quiz:quiz', :exam) }
  let(:item) { build(:'course:item', :quiz, :exam, item_params) }
  let(:item_params) do
    {
      section_id: section['id'],
      course_id: course['id'],
      content_id: quiz['id'],
      title: 'Exam 1',
      proctored: false,
    }
  end
  let(:quiz_update_stub) do
    Stub.request(
      :quiz, :put, "/quizzes/#{quiz['id']}",
      body: hash_including({})
    ).to_return Stub.json(quiz)
  end

  before do
    stub_user id: user_id,
      permissions: %w[course.content.access course.content.edit],
      features: {'proctoring' => 'true'}

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)
    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course['id'], user_id:}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section['id'])
    ).to_return Stub.json([item])
    Stub.request(
      :course, :get, "/items/#{item['id']}",
      query: hash_including({})
    ).to_return Stub.json(item)
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course['id']}
    ).to_return Stub.json([section])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])

    Stub.request(
      :quiz, :get, "/quizzes/#{quiz['id']}",
      query: hash_including({})
    ).to_return Stub.json(quiz)
    Stub.request(
      :quiz, :get, '/questions',
      query: hash_including(quiz_id: quiz['id'])
    ).to_return Stub.json([])

    quiz_update_stub
  end

  context 'for unproctored quiz' do
    let(:item_params) { {**super(), proctored: false} }

    it 'proctoring can be enabled' do
      visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
      expect(page).to have_content 'Edit item "Exam 1"'

      # Ensure that the prefilled values are set correctly.
      expect(page).to have_field('Title', with: 'Exam 1')
        .and have_select('Exercise type', selected: 'Main')
      expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

      # Enable proctoring.
      find('label', text: 'Enable proctoring?').click

      update_item = Stub.request(:course, :put, "/items/#{item['id']}")
        .to_return(status: 201)

      click_on 'Save item'

      expect(page).to have_content 'The item was updated successfully.'

      # Ensure that proctoring has been enabled for the item.
      expect(
        update_item.with(
          body: hash_including(
            'content_type' => 'quiz',
            'exercise_type' => 'main',
            'proctored' => true
          )
        )
      ).to have_been_requested
      # The content resource is updated successfully.
      expect(quiz_update_stub).to have_been_requested

      expect(page).to have_button 'Save and show item'
    end

    context '(starting with a self test)' do
      let(:quiz) { build(:'quiz:quiz') }
      let(:item) { build(:'course:item', :quiz, item_params) }
      let(:item_params) do
        {**super(), title: 'Selftest 1', exercise_type: 'selftest'}
      end

      it 'proctoring can be enabled when switching to main quiz' do
        visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
        expect(page).to have_content 'Edit item "Selftest 1"'

        # Ensure that the prefilled values are set correctly.
        expect(page).to have_field('Title', with: 'Selftest 1')
          .and have_select('Exercise type', selected: 'Self test')
        expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

        # Switch to main quiz; show the proctoring switch, enable proctoring by default.
        select 'Main', from: 'Exercise type'
        expect(page).to have_content 'Enable proctoring?'
        expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

        update_item = Stub.request(:course, :put, "/items/#{item['id']}")
          .to_return(status: 201)

        click_on 'Save item'

        expect(page).to have_content 'The item was updated successfully.'

        # Ensure that proctoring has been enabled for the item.
        expect(
          update_item.with(
            body: hash_including(
              'content_type' => 'quiz',
              'exercise_type' => 'main',
              'proctored' => true
            )
          )
        ).to have_been_requested
        # The content resource is updated successfully.
        expect(quiz_update_stub).to have_been_requested

        expect(page).to have_button 'Save and show item'
      end
    end
  end

  context 'for proctored quiz' do
    let(:item_params) { {**super(), proctored: true} }

    it 'proctoring can be disabled' do
      visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
      expect(page).to have_content 'Edit item "Exam 1"'

      # Ensure that the prefilled values are set correctly.
      expect(page).to have_field('Title', with: 'Exam 1')
        .and have_select('Exercise type', selected: 'Main')
      expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

      # Disable proctoring.
      find('label', text: 'Enable proctoring?').click

      update_item = Stub.request(:course, :put, "/items/#{item['id']}")
        .to_return(status: 201)

      click_on 'Save item'

      expect(page).to have_content 'The item was updated successfully.'

      # Ensure that proctoring has been disabled for the item.
      expect(
        update_item.with(
          body: hash_including(
            'content_type' => 'quiz',
            'exercise_type' => 'main',
            'proctored' => false
          )
        )
      ).to have_been_requested
      # The content resource is updated successfully.
      expect(quiz_update_stub).to have_been_requested

      expect(page).to have_button 'Save and show item'
    end

    it 'switching between quiz types maintains the proctoring state' do
      visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
      expect(page).to have_content 'Edit item "Exam 1"'

      # Ensure that the prefilled values are set correctly.
      expect(page).to have_field('Title', with: 'Exam 1')
        .and have_select('Exercise type', selected: 'Main')
      expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

      # Make the quiz a self test; don't show the proctoring switch.
      select 'Self test', from: 'Exercise type'
      expect(page).to have_no_content 'Enable proctoring?'
      expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

      # Switch back to main quiz; the proctoring state should be remembered.
      select 'Main', from: 'Exercise type'
      expect(page).to have_content 'Enable proctoring?'
      expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

      update_item = Stub.request(:course, :put, "/items/#{item['id']}")
        .to_return(status: 201)

      click_on 'Save item'

      expect(page).to have_content 'The item was updated successfully.'

      # Ensure that proctoring is still activated for the item.
      expect(
        update_item.with(
          body: hash_including(
            'content_type' => 'quiz',
            'exercise_type' => 'main',
            'proctored' => true
          )
        )
      ).to have_been_requested
      # The content resource is updated successfully.
      expect(quiz_update_stub).to have_been_requested

      expect(page).to have_button 'Save and show item'
    end
  end
end
