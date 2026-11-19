# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: Show', type: :request do
  subject(:show) do
    get "/learn/the_course/items/#{item_resource['id']}/quiz_submission/#{submission_id}"
  end

  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:request_context_id) { course.context_id }
  let(:course_context) { create(:'account_service/context') }
  let(:course) { create(:course, :active, course_code: 'the_course', context_id: course_context.id) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { create(:item, section:) }
  let(:item_resource) do
    build(:'course:item', :quiz, :exam,
      id: item.id, section_id: section.id, course_id: course.id, content_id: quiz.id)
  end
  let(:my_enrollment) { create(:enrollment, course:, user_id:) }

  let(:quiz) { create(:'quiz_service/quiz') }

  let(:submission_id) { short_uuid(requested_submission.id) }
  let(:requested_submission) do
    create(:'quiz_service/quiz_submission',
      quiz:,
      user_id: user.id,
      course_id: course.id,
      quiz_submission_time: 1.hour.ago)
  end
  let(:submissions_for_dropdown) { [requested_submission_payload] }
  let(:requested_submission_payload) { submission_payload_for.call(requested_submission) }
  let(:submission_payload_for) do
    lambda do |submission|
      QuizService::QuizSubmissionDecorator
        .new(submission)
        .as_json(api_version: 1)
        .merge(points: submission.points, max_points: submission.quiz.max_points)
    end
  end
  let(:permissions) { %w[course.content.access.available] }

  before do
    quiz_question = create(:'quiz_service/multiple_choice_question', quiz:, points: 10.0)
    create(:'quiz_service/quiz_submission_question',
      quiz_submission: requested_submission,
      quiz_question_id: quiz_question.id,
      points: 5.0)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:, context: course_context)
    sign_in(user:)

    # Stubs for the course the user is enrolled in and its structural content
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json([CourseService::EnrollmentDecorator.new(my_enrollment).as_json(api_version: 1)])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .to_return Stub.json(section_resource)
    Stub.request(:course, :get, "/items/#{item.id}", query: hash_including({}))
      .to_return Stub.json(item_resource)
  end

  context 'with more than one submission' do
    # The user has submitted answers to the same quiz multiple times.
    # Not all of them can be listed in the dropdown of submissions.
    let(:submissions_for_dropdown) do
      3.downto(1).map do |index|
        create(:'quiz_service/quiz_submission',
          quiz:,
          user_id: user.id,
          course_id: course.id,
          quiz_submission_time: index.days.ago,
          fudge_points: 0.0)
      end.map do |submission|
        submission_payload_for.call(submission)
      end
    end

    # The requested submission also belongs to our user, but does not appear in the dropdown.
    let(:requested_submission) do
      create(:'quiz_service/quiz_submission',
        quiz:,
        user_id: user.id,
        course_id: course.id,
        quiz_submission_time: 1.hour.ago,
        fudge_points: 0.0)
    end

    context 'when the submission belongs to the current user' do
      it 'the requested submission is displayed' do
        show
        expect(response).to be_successful
        expect(Capybara.string(response.body)).to have_text '5.0 of 10.0 points achieved'
      end

      it 'creates a visit' do
        show
        expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be true
      end
    end

    context 'when the requested submission does not belong to the current user' do
      let(:requested_submission) do
        create(:'quiz_service/quiz_submission',
          quiz:,
          course_id: course.id,
          quiz_submission_time: 1.hour.ago,
          fudge_points: 0.0)
      end

      it 'shows an error about lack of permissions and redirects to the home page' do
        show
        expect(flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
        expect(response).to redirect_to root_url
      end

      it 'does not create a visit' do
        show
        expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be false
      end
    end
  end

  context 'when the request has both an invalid submission ID and an unsupported format' do
    let(:submission_id) { 'highLightTitle.png' }

    it 'responds with 404 Not Found' do
      expect { show }.to raise_error Status::NotFound
      expect(CourseService::Visit.exists?(user_id:, item_id: item.id)).to be false
    end
  end
end
