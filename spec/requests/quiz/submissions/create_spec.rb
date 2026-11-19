# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: Create', type: :request do
  subject(:create_submission) do
    post "/learn/the_course/items/#{item.id}/quiz_submission",
      params:
  end

  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:request_context_id) { course.context_id }
  let(:course_context) { create(:'account_service/context') }
  let!(:course) { create(:course, :active, course_code: 'the_course', context_id: course_context.id) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { create(:item, section_id: section.id) }
  let(:item_resource) do
    build(:'course:item', :quiz, :exam,
      id: item.id,
      section_id: section.id,
      course_id: course.id,
      content_id: quiz.id)
  end
  let(:short_item_id) { UUID4.new(item.id).to_s(format: :base62) }
  let(:allowed_attempts) { 1 }
  let(:unlimited_time) { false }
  let(:unlimited_attempts) { false }
  let(:quiz) do
    create(:'quiz_service/quiz',
      allowed_attempts: allowed_attempts,
      unlimited_time: unlimited_time,
      unlimited_attempts: unlimited_attempts)
  end
  let(:short_submission_id) { UUID4.new(submission.id).to_s(format: :base62) }
  let(:submission_created_at) { 30.minutes.ago }
  let(:submission) do
    create(:'quiz_service/quiz_submission',
      quiz:,
      user_id: user.id,
      course_id: course.id,
      created_at: submission_created_at,
      quiz_submission_time: nil)
  end
  let(:attempts) { 0 }

  let(:params) do
    {
      quiz_id: quiz.id,
      quiz_submission_id: submission.id,
      submission: {
        # See the `QuizSubmissionsController#update` in xi-quiz for details.
        # For single select questions:
        #   question id => id of selected answer
        generate(:question_id) => SecureRandom.uuid,
      },
    }.compact
  end
  let(:update_submission_stub) do
    Stub.request(:quiz, :put, "/quiz_submissions/#{submission.id}")
      .to_return Stub.response(status: 200)
  end

  let(:permissions) { %w[course.content.access.available] }

  before do
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:, context: course_context)
    sign_in(user:)

    create(:enrollment, course:, user_id:)

    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(CourseService::CourseDecorator.new(course).as_json(api_version: 1))
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course.id))
      .to_return Stub.json([section_resource])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
      .to_return Stub.json([item_resource])
    Stub.request(:course, :get, "/items/#{item.id}", query: hash_including({}))
      .to_return Stub.json(item_resource)

    Stub.request(:quiz, :get, "/quizzes/#{quiz.id}")
      .to_return Stub.json(quiz.decorate.as_json(api_version: 1))
    Stub.request(
      :quiz, :get, '/user_quiz_attempts',
      query: hash_including(quiz_id: quiz.id, user_id:)
    ).to_return Stub.json({attempts:, additional_attempts: 0})
    Stub.request(:quiz, :get, "/quiz_submissions/#{submission.id}")
      .to_return Stub.json(submission.decorate.as_json(api_version: 1))
    update_submission_stub
  end

  context 'without a quiz for the submission (missing content resource)' do
    let(:params) { super().merge(quiz_id: nil) }

    it 'does not update the submission' do
      create_submission
      expect(update_submission_stub).not_to have_been_requested
    end

    it 'redirects to the quiz item and notifies about failed submission' do
      create_submission
      expect(response).to redirect_to course_item_url(id: short_item_id)
      expect(flash[:error].first).to eq 'Your quiz solution has not been submitted correctly.'
    end
  end

  context 'for a quiz with time limit' do
    context 'submitting within the time limit' do
      it 'updates the submission with selected answers' do
        create_submission
        expect(update_submission_stub.with(
          body: hash_including(submitted: true, submission: params[:submission])
        )).to have_been_requested
      end

      it 'redirects to and confirms successful submission' do
        create_submission
        expect(response).to redirect_to course_item_quiz_submission_url(
          id: short_submission_id,
          highest_score: false
        )
        expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
      end

      context 'when the submission data (selected answers) already exists' do
        let(:update_submission_stub) do
          Stub.request(:quiz, :put, "/quiz_submissions/#{submission.id}")
            .with(
              body: hash_including(submitted: true, submission: params[:submission])
            ).to_return Stub.response(status: 422)
        end

        it 'marks the submission as submitted' do
          create_submission
          expect(
            Stub.request(:quiz, :put, "/quiz_submissions/#{submission.id}")
              .with(
                body: hash_including(submitted: true)
              ).to_return(Stub.response(status: 200))
          ).to have_been_requested
        end

        it 'redirects to and confirms successful submission' do
          create_submission
          expect(response).to redirect_to course_item_quiz_submission_url(
            id: short_submission_id,
            highest_score: false
          )
          expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
        end
      end

      context 'with further attempts' do
        let(:allowed_attempts) { 2 }

        it 'updates the submission with selected answers' do
          create_submission
          expect(update_submission_stub.with(
            body: hash_including(submitted: true, submission: params[:submission])
          )).to have_been_requested
        end

        it 'redirects to the quiz item and confirms successful submission' do
          create_submission
          expect(response).to redirect_to course_item_url(id: short_item_id)
          expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
        end
      end

      context 'last attempt' do
        let(:allowed_attempts) { 2 }
        let(:attempts) { 1 }

        it 'updates the submission with selected answers' do
          create_submission
          expect(update_submission_stub.with(
            body: hash_including(submitted: true, submission: params[:submission])
          )).to have_been_requested
        end

        it 'redirects to the submission and notifies about missing answers' do
          create_submission
          expect(response).to redirect_to course_item_quiz_submission_url(
            id: short_submission_id,
            highest_score: false
          )
          expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
        end
      end

      context 'without submission data' do
        let(:params) { super().merge(submission: nil) }

        it 'marks the submission as submitted' do
          create_submission
          expect(update_submission_stub.with(
            body: hash_including(submitted: true)
          )).to have_been_requested
        end

        it 'redirects to the submission and notifies about missing answers' do
          create_submission
          expect(response).to redirect_to course_item_quiz_submission_url(
            id: short_submission_id,
            highest_score: false
          )
          expect(flash[:error].first).to eq 'No answers were submitted for your quiz solution.'
        end
      end
    end

    context 'not submitting within the time limit' do
      let(:submission_created_at) { 1.day.ago }

      it 'marks the submission as submitted' do
        create_submission
        expect(update_submission_stub.with(
          body: hash_including(submitted: true)
        )).to have_been_requested
      end

      it 'redirects to the submission and notifies about the exceeded time limit' do
        create_submission
        expect(response).to redirect_to course_item_quiz_submission_url(
          id: short_submission_id,
          highest_score: false
        )
        expect(flash[:error].first).to eq 'The time for your active quiz is up.'
      end
    end
  end

  context 'for a quiz without time limit' do
    let(:unlimited_time) { true }

    it 'updates the submission with selected answers' do
      create_submission
      expect(update_submission_stub.with(
        body: hash_including(submitted: true, submission: params[:submission])
      )).to have_been_requested
    end

    it 'redirects to and confirms successful submission' do
      create_submission
      expect(response).to redirect_to course_item_quiz_submission_url(
        id: short_submission_id,
        highest_score: false
      )
      expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
    end

    context 'and with unlimited attempts' do
      let(:unlimited_time) { true }
      let(:unlimited_attempts) { true }

      it 'updates the submission with selected answers' do
        create_submission
        expect(update_submission_stub.with(
          body: hash_including(submitted: true, submission: params[:submission])
        )).to have_been_requested
      end

      it 'redirects to the quiz item and confirms successful submission' do
        create_submission
        expect(response).to redirect_to course_item_url(id: short_item_id)
        expect(flash[:success].first).to eq 'Your quiz solution has been submitted successfully.'
      end
    end
  end
end
