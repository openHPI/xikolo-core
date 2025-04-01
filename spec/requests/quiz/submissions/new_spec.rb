# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: New', type: :request do
  subject(:new_submission) do
    get "/courses/the_course/items/#{item.id}/quiz_submission/new",
      headers: {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:user_id) { generate(:user_id) }
  let(:request_context_id) { course.context_id }
  let(:course) do
    create(:course, :active, course_code: 'the_course', title: 'Automated Quiz Submissions 101')
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

  let(:quiz_id) { generate(:quiz_id) }
  let(:quiz_question) { build(:'quiz:question', :free_text, quiz_id:) }
  let(:submission_deadline) { 1.hour.from_now }
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
    stub_user_request id: user_id, language: 'en',
      permissions: ['course.content.access.available'],
      features: {'proctoring' => true}

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course.as_json)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([my_enrollment.as_json])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including(course_id: course.id)
    ).to_return Stub.json([])
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

    Stub.service :quiz, build(:'quiz:root')
    Stub.request(
      :quiz, :get, "/quizzes/#{quiz_id}"
    ).to_return Stub.json(build(:'quiz:quiz', :exam, id: quiz_id))
    Stub.request(
      :quiz, :get, '/questions',
      query: {quiz_id:, per_page: '250'}
    ).to_return Stub.json([])
    Stub.request(:quiz, :get, '/questions', query: hash_including(quiz_id:))
      .to_return Stub.json([quiz_question])
    Stub.request(:quiz, :get, '/answers', query: hash_including(question_id: quiz_question['id']))
      .to_return Stub.json([
        build(:'quiz:answer', :free_text, question_id: quiz_question['id']),
      ])

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
    expect(page).to have_content 'What is the answer?'
    expect(page).to have_link 'Send my final answers'

    # The service returned a new quiz submission
    expect(page).to have_no_content 'There is still an active quiz running.'
  end

  it 'creates a new quiz submission' do
    new_submission

    expect(
      create_submission_stub.with(body: {
        course_id: course.id,
        quiz_id:,
        user_id:,
        vendor_data: nil,
      })
    ).to have_been_requested
  end

  context 'when the server returns a re-used quiz submission' do
    let(:created_submission_status) { 200 }

    it 'displays a message to warn the user' do
      new_submission

      expect(response).to be_successful

      expect(page).to have_content 'What is the answer?'
      expect(page).to have_link 'Send my final answers'

      expect(page).to have_content 'There is still an active quiz running.'
    end
  end

  context 'if deadline passed' do
    let(:submission_deadline) { 1.hour.ago }

    it 'redirects to course item page' do
      expect(new_submission).to redirect_to "/courses/the_course/items/#{short_uuid(item.id)}"
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
      expect(new_submission).to redirect_to "/courses/the_course/items/#{short_uuid(item.id)}"
    end
  end

  describe '(proctoring)' do
    let(:course) do
      create(:course, :active, :offers_proctoring, course_code: 'the_course', title: 'Automated Quiz Submissions 101')
    end
    let(:my_enrollment) { create(:enrollment, :proctored, course:, user_id:) }
    let(:item_resource) do
      build(:'course:item', :quiz, :exam, :proctored,
        id: item.id, section_id: section.id, course_id: course.id, content_id: quiz_id,
        submission_deadline:)
    end

    it 'does not create a submission and redirects back to the quiz intro page' do
      new_submission

      expect(create_submission_stub).not_to have_been_requested

      expect(response).to redirect_to "/courses/the_course/items/#{short_uuid(item.id)}"
      expect(flash[:error].first).to eq 'The proctored exam could not be started. Please try again later.'
    end
  end
end
