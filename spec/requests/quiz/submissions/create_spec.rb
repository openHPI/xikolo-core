# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz: Submissions: Create', type: :request do
  subject(:create_submission) do
    post "/courses/the_course/items/#{item['id']}/quiz_submission",
      headers: {Authorization: "Xikolo-Session session_id=#{stub_session_id}"},
      params:
  end

  let(:user_id) { submission['user_id'] }
  let(:request_context_id) { course.context_id }
  let!(:course) { create(:course, :active, course_code: 'the_course') }
  let!(:my_enrollment) { create(:enrollment, course:, user_id:) }
  let(:section) { build(:'course:section', course_id: course.id) }
  let(:item) do
    build(:'course:item', :quiz, :exam,
      section_id: section['id'],
      course_id: course.id,
      content_id: quiz['id'])
  end
  let(:short_item_id) { UUID4.new(item['id']).to_s(format: :base62) }
  let(:quiz) { build(:'quiz:quiz', :exam) }
  let(:quiz_question) { build(:'quiz:question', quiz_id: quiz['id']) }
  let(:quiz_answer) do
    build(:'quiz:answer', question_id: quiz_question['id'], quiz_id: quiz['id'])
  end
  let(:short_submission_id) { UUID4.new(submission['id']).to_s(format: :base62) }
  let(:submission) { build(:'quiz:submission', **submission_attrs) }
  let(:submission_attrs) do
    {
      course_id: course.id,
      quiz_id: quiz['id'],
      submitted: false,
      quiz_access_time: 30.minutes.ago.iso8601,
      quiz_submission_time: nil,
    }
  end
  let(:attempts) { 0 }

  let(:params) do
    {
      quiz_id: quiz['id'],
      quiz_submission_id: submission['id'],
      submission: {
        # See the `QuizSubmissionsController#update` in xi-quiz for details.
        # For single select questions:
        #   question id => id of selected answer
        quiz_question['id'] => quiz_answer['id'],
      },
    }.compact
  end
  let(:update_submission_stub) do
    Stub.request(:quiz, :put, "/quiz_submissions/#{submission['id']}")
      .to_return Stub.response(status: 200)
  end

  before do
    stub_user_request id: user_id,
      permissions: %w[course.content.access.available],
      features: {'proctoring' => true}

    Stub.service(:course, build(:'course:root'))
    Stub.service(:quiz, build(:'quiz:root'))

    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course.as_json)
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json([my_enrollment.as_json])
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course.id))
      .to_return Stub.json([section])
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section['id']))
      .to_return Stub.json([item])
    Stub.request(:course, :get, "/items/#{item['id']}", query: hash_including({}))
      .to_return Stub.json(item)

    Stub.request(:quiz, :get, "/quizzes/#{quiz['id']}")
      .to_return Stub.json(quiz)
    Stub.request(
      :quiz, :get, '/user_quiz_attempts',
      query: hash_including(quiz_id: quiz['id'], user_id:)
    ).to_return Stub.json({attempts:, additional_attempts: 0})
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
    ).to_return Stub.json([submission])
    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: hash_including(newest_first: 'true', quiz_id: quiz['id'], user_id:)
    ).to_return Stub.json([submission])
    Stub.request(:quiz, :get, "/quiz_submissions/#{submission['id']}")
      .to_return Stub.json(submission)
    update_submission_stub

    # Fetch the created submission after creation
    Stub.request(
      :quiz, :get, '/quiz_submissions',
      query: hash_including(quiz_id: quiz['id'], user_id:, per_page: '1')
    ).to_return Stub.json([submission])
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

      it 'publishes an event for the submission' do
        expect(Msgr).to receive(:publish).once.with(
          hash_including(id: submission['id']),
          hash_including(to: 'xikolo.submission.submission.create')
        )
        create_submission
      end

      context 'when the submission data (selected answers) already exists' do
        let(:update_submission_stub) do
          Stub.request(:quiz, :put, "/quiz_submissions/#{submission['id']}")
            .with(
              body: hash_including(submitted: true, submission: params[:submission])
            ).to_return Stub.response(status: 422)
        end

        it 'marks the submission as submitted' do
          create_submission
          expect(
            Stub.request(:quiz, :put, "/quiz_submissions/#{submission['id']}")
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

        it 'publishes an event for the submission' do
          expect(Msgr).to receive(:publish).once.with(
            hash_including(id: submission['id']),
            hash_including(to: 'xikolo.submission.submission.create')
          )
          create_submission
        end
      end

      context 'with further attempts' do
        let(:quiz) { build(:'quiz:quiz', :exam, current_allowed_attempts: 2) }

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
        let(:quiz) { build(:'quiz:quiz', :exam, current_allowed_attempts: 2) }
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
      let(:submission_attrs) { super().merge(quiz_access_time: 1.day.ago.iso8601) }

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
    let(:quiz) do
      build(:'quiz:quiz', :exam, current_unlimited_time: true)
    end

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

    it 'publishes an event for the submission' do
      expect(Msgr).to receive(:publish).once.with(
        hash_including(id: submission['id']),
        hash_including(to: 'xikolo.submission.submission.create')
      )
      create_submission
    end

    context 'and with unlimited attempts' do
      let(:quiz) do
        build(:'quiz:quiz',
          current_unlimited_time: true,
          current_unlimited_attempts: true)
      end

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
