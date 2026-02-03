# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: Show', type: :request do
  subject(:show) do
    get "/courses/the_course/items/#{item_resource['id']}/quiz_submission/#{submission_id}",
      headers: {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:user_id) { requested_submission['user_id'] }
  let(:request_context_id) { course.context_id }
  let(:course) { create(:course, :active, course_code: 'the_course') }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { create(:item, section:) }
  let(:item_resource) do
    build(:'course:item', :quiz, :exam,
      id: item.id, section_id: section.id, course_id: course.id, content_id: quiz['id'])
  end
  let(:my_enrollment) { create(:enrollment, course:, user_id:) }

  let(:quiz) { build(:'quiz:quiz', :exam) }
  let(:quiz_question) { build(:'quiz:question', quiz_id: quiz['id']) }
  let(:quiz_answer) do
    build(:'quiz:answer', question_id: quiz_question['id'], quiz_id: quiz['id'])
  end

  let(:submission_id) { short_uuid(requested_submission['id']) }
  let(:requested_submission) { build(:'quiz:submission', **submission_attrs) }
  let(:submission_attrs) do
    {
      course_id: course.id,
      quiz_id: quiz['id'],
      submitted: true,
      quiz_submission_time: 1.hour.ago.iso8601,
    }
  end
  let(:submissions_for_dropdown) { [requested_submission] }
  let(:submission_question) do
    build(:'quiz:submission_question',
      quiz_submission_id: requested_submission['id'],
      quiz_question_id: quiz_question['id'])
  end
  let(:submission_answer) do
    build(:'quiz:submission_answer',
      quiz_submission_question_id: submission_question['id'],
      quiz_answer_id: quiz_answer['id'])
  end
  let(:visit_stub) do
    Stub.request(:course, :post, "/items/#{item.id}/users/#{user_id}/visit")
  end

  before do
    stub_user_request id: user_id,
      permissions: %w[course.content.access.available],
      features: {'proctoring' => true}

    # Stubs for the course the user is enrolled in and its structural content
    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course.as_json)
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json([my_enrollment.as_json])
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course.id))
      .to_return Stub.json([section_resource])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
      .to_return Stub.json([item_resource])
    Stub.request(:course, :get, "/items/#{item.id}", query: hash_including({}))
      .to_return Stub.json(item_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    # Stubs for the quiz taken by the user
    Stub.request(:quiz, :get, "/quizzes/#{quiz['id']}")
      .to_return Stub.json(quiz)
    Stub.request(
      :quiz, :get, '/user_quiz_attempts',
      query: hash_including(quiz_id: quiz['id'], user_id:)
    ).to_return Stub.json({attempts: 3, additional_attempts: 0})
    Stub.request(
      :quiz, :get, '/questions',
      query: hash_including(quiz_id: quiz['id'])
    ).to_return Stub.json([quiz_question])
    Stub.request(
      :quiz, :get, '/answers',
      query: hash_including(question_id: quiz_question['id'])
    ).to_return Stub.json([quiz_answer])
    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: hash_including(highest_score: 'false', newest_first: 'false', quiz_id: quiz['id'], user_id:)
    ).to_return Stub.json(submissions_for_dropdown)
    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: hash_including(newest_first: 'true', quiz_id: quiz['id'], user_id:)
    ).to_return Stub.json(submissions_for_dropdown)

    # Explicitly stub the requested submission
    Stub.request(:quiz, :get, "/quiz_submissions/#{requested_submission['id']}")
      .to_return Stub.json(requested_submission)
    Stub.request(
      :quiz, :get, '/quiz_submission_questions',
      query: hash_including(quiz_submission_id: requested_submission['id'])
    ).to_return Stub.json([submission_question])
    Stub.request(
      :quiz, :get, '/quiz_submission_answers',
      query: hash_including(quiz_submission_question_id: submission_question['id'])
    ).to_return Stub.json([submission_answer])
    visit_stub
  end

  describe 'proctored submission' do
    let(:course) { create(:course, :active, :offers_proctoring, course_code: 'the_course') }
    let(:my_enrollment) { create(:enrollment, :proctored, course:, user_id:) }
    let(:item_resource) do
      build(:'course:item', :quiz, :exam, :proctored,
        id: item.id,
        section_id: section.id,
        course_id: course.id,
        content_id: quiz['id'])
    end

    context 'user passed proctoring (SMOWL v1)' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v1_passed, **submission_attrs) }

      it 'mentions that everything is okay' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'No issues detected'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'user passed proctoring (SMOWL v2)' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v2_passed, **submission_attrs) }

      it 'mentions that everything is okay' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'No issues detected'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'user passed proctoring (SMOWL v1) with a few violations' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v1_passed_with_violations, **submission_attrs) }

      it 'mentions minor issues' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'There have been some minor issues during the proctoring for this assignment.'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'user passed proctoring (SMOWL v2) with a few violations' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v2_passed_with_violations, **submission_attrs) }

      it 'mentions minor issues' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'There have been some minor issues during the proctoring for this assignment.'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'user failed proctoring (SMOWL v1) b/c of too many violations' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v1_failed, **submission_attrs) }

      it 'mentions certificate is out of reach' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'There have been issues during the proctoring for this assignment. A certificate will not be issued.'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'user failed proctoring (SMOWL v2) b/c of too many violations' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v2_failed, **submission_attrs) }

      it 'mentions certificate is out of reach' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'There have been issues during the proctoring for this assignment. A certificate will not be issued.'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'proctoring results have not yet been processed' do
      let(:requested_submission) { build(:'quiz:submission', :proctoring_smowl_v2_pending, **submission_attrs) }

      it 'mentions processing of proctoring data' do
        show
        expect(response.body).to include 'Online proctoring results'
        expect(response.body).to include 'The proctoring data is still being processed.'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end
  end

  context 'with more than one submission' do
    # The user has submitted answers to the same quiz multiple times.
    # Not all of them can be listed in the dropdown of submissions.
    let(:submissions_for_dropdown) do
      3.downto(1).map do |index|
        build(:'quiz:submission',
          **submission_attrs,
          points: index.to_f,
          quiz_submission_time: index.days.ago.iso8601)
      end
    end

    # The requested submission also belongs to our user, but does not appear in the dropdown.
    let(:requested_submission) { build(:'quiz:submission', **submission_attrs, points: 5.0) }

    context 'when the submission belongs to the current user' do
      it 'the requested submission is displayed' do
        show
        expect(response).to be_successful
        expect(Capybara.string(response.body)).to have_content '5.0 of 10.0 points achieved'
      end

      it 'creates a visit' do
        show
        expect(visit_stub).to have_been_requested
      end
    end

    context 'when the requested submission does not belong to the current user' do
      let(:user_id) { generate(:user_id) }

      it 'shows an error about lack of permissions and redirects to the home page' do
        show
        expect(flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
        expect(response).to redirect_to root_url
      end

      it 'does not create a visit' do
        show
        expect(visit_stub).not_to have_been_requested
      end
    end
  end

  context 'when the request has both an invalid submission ID and an unsupported format' do
    let(:submission_id) { 'highLightTitle.png' }

    it 'responds with 404 Not Found' do
      expect { show }.to raise_error Status::NotFound
      expect(visit_stub).not_to have_been_requested
    end
  end
end
