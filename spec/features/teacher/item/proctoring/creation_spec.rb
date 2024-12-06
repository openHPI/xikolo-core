# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Item: Proctoring: Create Item', gen: 2, type: :feature do
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
  let(:quiz_create_stub) do
    Stub.request(
      :quiz, :post, '/quizzes',
      body: hash_including({})
    ).to_return Stub.json(new_quiz)
  end
  let(:new_item) { build(:'course:item', :quiz, course_id: course['id'], section_id: section['id'], content_id: new_quiz['id']) }
  let(:new_quiz) { build(:'quiz:quiz') }

  before do
    stub_user id: user_id,
      permissions: %w[course.content.access course.content.edit],
      features: {'proctoring' => 'true'}
    Stub.service(:course, build(:'course:root'))
    Stub.service(:peerassessment, build(:'peerassessment:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))
    Stub.service(:quiz, build(:'quiz:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)
    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course['id'], user_id:}
    ).to_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course['id']}
    ).to_return Stub.json([section])
    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section['id'])
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :peerassessment, :get, '/peer_assessments',
      query: {course_id: course['id']}
    ).to_return Stub.json([])

    # Stubs for processing and the "Edit item" page shown after saving
    Stub.request(
      :pinboard, :post, '/implicit_tags',
      body: hash_including(course_id: course['id'], referenced_resource: 'Xikolo::Course::Item')
    ).to_return Stub.json({})
    Stub.request(
      :course, :get, "/items/#{new_item['id']}"
    ).to_return Stub.json(new_item)
    Stub.request(
      :course, :get, "/items/#{new_item['id']}", query: {raw: '1'}
    ).to_return Stub.json(new_item)
    Stub.request(
      :quiz, :get, "/quizzes/#{new_quiz['id']}", query: {raw: 'true'}
    ).to_return Stub.json(new_quiz)
    Stub.request(
      :quiz, :get, '/questions', query: hash_including(quiz_id: new_quiz['id'])
    ).to_return Stub.json([])

    quiz_create_stub
  end

  it 'sets proctoring state defaults correctly' do
    visit "/courses/the_course/sections/#{section['id']}/items/new"
    expect(page).to have_content 'Create new item in section "Week 1"'

    fill_in 'Title', with: 'Unproctored main quiz'
    select 'Quiz', from: 'Type'
    expect(page).to have_no_content 'Enable proctoring?'

    # For bonus quizzes, show the proctoring switch; it's set to false by default.
    select 'Bonus', from: 'Exercise type'
    expect(page).to have_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

    # Enable proctoring.
    find('label', text: 'Enable proctoring?').click

    # Surveys cannot be proctored; don't show the proctoring switch.
    # Ensure that proctoring is disabled for the item by default (although it
    # has been manually enabled for the bonus quiz before).
    select 'Survey', from: 'Exercise type'
    expect(page).to have_no_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

    # Self tests cannot be proctored; don't show the proctoring switch.
    select 'Self test', from: 'Exercise type'
    expect(page).to have_no_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

    # For main quizzes, show the proctoring switch; it's set to true by default.
    select 'Main', from: 'Exercise type'
    expect(page).to have_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

    # Disable proctoring setting.
    find('label', text: 'Enable proctoring?').click

    # Switching to another quiz type and back does not remember
    # the proctoring state.
    select 'Survey', from: 'Exercise type'
    expect(page).to have_no_content 'Enable proctoring?'
    select 'Main', from: 'Exercise type'
    expect(page).to have_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).to be_checked

    # Disable proctoring.
    find('label', text: 'Enable proctoring?').click

    create_item = Stub.request(:course, :post, '/items')
      .to_return Stub.json(new_item)

    click_on 'Create Item'
    # Since there is no flash message when a quiz item has been created, we
    # check that the quiz settings for this item are shown.
    expect(page).to have_content 'Quiz settings'

    # Ensure that proctoring has not been enabled for the item.
    expect(
      create_item.with(
        body: hash_including(
          'content_type' => 'quiz',
          'exercise_type' => 'main',
          'proctored' => false
        )
      )
    ).to have_been_requested

    # The content resource is created successfully.
    expect(quiz_create_stub).to have_been_requested
  end

  it 'proctoring can be enabled for quizzes' do
    visit "/courses/the_course/sections/#{section['id']}/items/new"
    expect(page).to have_content 'Create new item in section "Week 1"'

    fill_in 'Title', with: 'Proctored bonus quiz'
    select 'Quiz', from: 'Type'
    expect(page).to have_no_content 'Enable proctoring?'

    # For bonus quizzes, show the proctoring switch; it's set to false by default.
    select 'Bonus', from: 'Exercise type'
    expect(page).to have_content 'Enable proctoring?'
    expect(page.find_field('Enable proctoring?', visible: false)).not_to be_checked

    # Enable proctoring.
    find('label', text: 'Enable proctoring?').click

    create_item = Stub.request(:course, :post, '/items')
      .to_return Stub.json(new_item)

    click_on 'Create Item'
    # Since there is no flash message when a quiz item has been created, we
    # check that the quiz settings for this item are shown.
    expect(page).to have_content 'Quiz settings'

    # Ensure that proctoring has been enabled for the item.
    expect(
      create_item.with(
        body: hash_including(
          'content_type' => 'quiz',
          'exercise_type' => 'bonus',
          'proctored' => true
        )
      )
    ).to have_been_requested

    # The content resource is created successfully.
    expect(quiz_create_stub).to have_been_requested
  end
end
