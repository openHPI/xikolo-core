# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Attachment Specs', gen: 2, type: :feature do
  let(:user_id) { generate(:user_id) }
  let(:question) { build(:'pinboard:question', course_id: course['id'], updated_at: 1.day.ago) }
  let(:course) do
    build(:'course:course',
      course_code: 'our_course',
      title: 'Automated Testing (2018 Edition)')
  end

  before do
    stub_user permissions: %w[course.content.access.available], id: user_id
    Stub.service(:course, build(:'course:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json({id: user_id})
    Stub.request(:course, :get, '/courses/our_course')
      .and_return Stub.json(course)
    Stub.request(:course, :get, "/courses/#{course['id']}")
      .and_return Stub.json(course)
    Stub.request(:course, :get, '/api/v2/course/courses/our_course?embed=description,enrollment')
      .and_return Stub.json(course)
    Stub.request(:course, :get, "/enrollments?course_id=#{course['id']}&user_id=#{user_id}")
      .and_return Stub.json([{}])
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course['id']))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/items', query: hash_including(course_id: course['id']))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/questions', query: hash_including(course_id: course['id']))
      .to_return Stub.json([question])
    Stub.request(:pinboard, :get, '/tags', query: hash_including(course_id: course['id']))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/explicit_tags', query: hash_including(course_id: course['id']))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, "/questions/#{question['id']}")
      .to_return Stub.json(question)
  end

  it 'displays error message when select unacceptable attachments for question' do
    visit '/courses/our_course/pinboard'

    click_on 'Start a new topic'

    attach_file 'Attachment', Rails.root.join('app/assets/fonts/OpenSansRegular.woff')

    expect(page).to have_content 'is not a valid document file'
  end

  it 'displays error message when select unacceptable attachments for answer' do
    Stub.request(:pinboard, :get, "/questions/#{question['id']}?vote_value_for_user_id=#{user_id}&watch_for_user_id=#{user_id}")
      .and_return Stub.json({id: question['id'], title: 'Test Question', implicit_tags: [], explicit_tags: [], user_id:, created_at: 1.minute.ago})
    Stub.request(:pinboard, :get, "/subscriptions?question_id=#{question['id']}&user_id=#{user_id}")
      .and_return Stub.json([])
    Stub.request(:pinboard, :get, "/explicit_tags?question_id=#{question['id']}")
      .and_return Stub.json([])
    Stub.request(:pinboard, :get, "/comments?blocked=false&commentable_id=#{question['id']}&commentable_type=Question&per_page=250&watch_for_user_id=#{user_id}")
      .and_return Stub.json([])
    Stub.request(:pinboard, :get, "/answers?blocked=false&per_page=250&question_id=#{question['id']}&sort=created_at&vote_value_for_user_id=#{user_id}&watch_for_user_id=#{user_id}")
      .and_return Stub.json([])

    visit "/courses/our_course/question/#{question['id']}"

    attach_file 'Attachment', Rails.root.join('app/assets/fonts/OpenSansRegular.woff'), id: 'xikolo_pinboard_answer_attachment'

    expect(page).to have_content 'is not a valid document file'
  end
end
