# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: New', type: :request do
  subject(:new_submission) do
    get "/learn/the_course/items/#{item.id}/quiz_submission/new"
  end

  let(:permissions) { ['course.content.access.available'] }
  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:request_context_id) { course.context_id }
  let(:course_context) { create(:'account_service/context') }
  let(:course) do
    create(:course, :active, course_code: 'the_course', title: 'Automated Quiz Submissions 101', context_id: course_context.id)
  end
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { create(:item, section:) }
  let(:item_resource) do
    build(:'course:item', :quiz, :exam,
      id: item.id, section_id: section.id, course_id: course.id, content_id: quiz_id,
      submission_deadline:)
  end
  let(:my_enrollment) { create(:enrollment, course:, user_id:) }

  let(:quiz) { create(:'quiz_service/quiz') }
  let(:quiz_id) { quiz.id }
  let(:quiz_question) { create(:'quiz_service/free_text_question', quiz:, text: 'What is the answer?') }
  let(:quiz_payload) { QuizService::QuizDecorator.new(quiz).as_json(api_version: 1) }
  let(:submission_deadline) { 1.hour.from_now.iso8601(3) }
  let(:create_submission_stub) do
    Stub.request(
      :quiz, :post, '/quiz_submissions'
    ).to_return Stub.json({
      id: SecureRandom.uuid,
      quiz_access_time: DateTime.now.iso8601,
      course_id: course.id,
      user_id:,
    }, status: created_submission_status)
  end
  let(:created_submission_status) { 201 }

  let(:page) { Capybara.string(response.body) }

  around {|example| Timecop.freeze(&example) }

  before do
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:, context: course_context)
    sign_in(user:)

    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(CourseService::CourseDecorator.new(course).as_json(api_version: 1))
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([CourseService::EnrollmentDecorator.new(my_enrollment).as_json(api_version: 1)])
    Stub.request(
      :course, :get, "/sections/#{section.id}"
    ).to_return Stub.json(section_resource)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, "/items/#{item.id}",
      query: {user_id:}
    ).to_return Stub.json(item_resource)
    Stub.request(
      :course, :get, '/items',
      query: {section_id: section.id, state_for: user_id, published: 'true'}
    ).to_return Stub.json([])

    Stub.request(
      :quiz, :get, "/quizzes/#{quiz_id}"
    ).to_return Stub.json(quiz_payload)
    Stub.request(:quiz, :get, '/questions', query: hash_including(quiz_id:))
      .to_return Stub.json([QuizService::QuestionDecorator.new(quiz_question).as_json(api_version: 1)])

    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: {quiz_id:, user_id:, newest_first: 'true'}
    ).to_return Stub.json([])
    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: {quiz_id:, user_id:, submitted: 'false'}
    ).to_return Stub.json([])
    Stub.request(
      :quiz, :get, '/user_quiz_attempts',
      query: {user_id:, quiz_id:}
    ).to_return Stub.json({
      additional_attempts: 0,
      attempts: 0,
    })
    create_submission_stub
  end

  it 'displays all questions' do
    new_submission

    expect(response).to be_successful

    # First and only question
    expect(page).to have_text 'What is the answer?'
    expect(page).to have_button 'Send my final answers'

    # The service returned a new quiz submission
    expect(page).to have_no_text 'There is still an active quiz running.'
  end

  it 'creates a visit' do
    new_submission
    expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be true
  end

  it 'creates a new quiz submission' do
    new_submission

    expect(
      create_submission_stub.with(body: {
        course_id: course.id,
        quiz_id:,
        user_id:,
      })
    ).to have_been_requested
  end

  context 'when the server returns a re-used quiz submission' do
    let(:created_submission_status) { 200 }

    it 'displays a message to warn the user' do
      new_submission

      expect(response).to be_successful

      expect(page).to have_text 'What is the answer?'
      expect(page).to have_button 'Send my final answers'

      expect(page).to have_text 'There is still an active quiz running.'
    end

    it 'creates a visit' do
      new_submission
      expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be true
    end
  end

  context 'if deadline passed' do
    let(:submission_deadline) { 1.hour.ago.iso8601(3) }

    it 'redirects to course item page' do
      expect(new_submission).to redirect_to "/learn/the_course/items/#{short_uuid(item.id)}"
    end

    it 'does not create a visit' do
      new_submission
      expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be false
    end
  end

  context 'if no attempts left' do
    before do
      Stub.request(
        :quiz, :post, '/quiz_submissions',
        body: hash_including(course_id: course.id, quiz_id:, user_id:)
      ).to_return Stub.response(status: 422)
    end

    it 'redirects to course item page' do
      expect(new_submission).to redirect_to "/learn/the_course/items/#{short_uuid(item.id)}"
    end

    it 'does not create a visit' do
      new_submission
      expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be false
    end
  end
end
