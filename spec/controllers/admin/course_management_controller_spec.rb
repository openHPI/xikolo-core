# frozen_string_literal: true

require 'spec_helper'

describe Admin::CourseManagementController, type: :controller do
  let(:user) { create(:'account_service/user', id: user_id, language: 'en') }
  let(:permissions) { [] }
  let(:user_id) { SecureRandom.uuid }
  let(:enroll_user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:submission_id) { SecureRandom.uuid }
  let(:snapshot_id) { SecureRandom.uuid }
  let(:course_code) { 'the-code' }
  let(:course) { create(:'course_service/course', id: course_id, course_code:) }
  let(:course_context) { AccountService::Context.root }

  around {|example| Timecop.freeze(&example) }

  before do
    course
    sign_in(user: user, permissions:) if user

    Stub.request(
      :course, :post, '/enrollments',
      body: hash_including(user_id: enroll_user_id, course_id:)
    ).to_return Stub.json({
      course_id:,
      user_id: enroll_user_id,
    })

    Stub.request(
      :quiz, :get, "/quiz_submissions/#{submission_id}"
    ).to_return Stub.json({
      id: submission_id,
    })
    Stub.request(
      :quiz, :get, "/quiz_submission_snapshots/#{snapshot_id}"
    ).to_return Stub.json({
      id: snapshot_id,
    })
  end

  describe '#import_quizzes' do
    subject(:action) { -> { post :import_quizzes, params: } }

    let(:permissions) { ['course.content.edit'] }
    let(:params) { {id: course_id, spreadsheet: 'abc', worksheet: 'xyz'} }

    context 'with successful import' do
      before do
        allow(QuizImporter).to receive(:import).with(
          spreadsheet: params[:spreadsheet],
          worksheet: params[:worksheet],
          course_code: course_code
        ).and_return(true)
      end

      it 'sets a proper flash message' do
        action.call
        expect(flash[:success]).to include 'Quizzes successfully imported!'
      end
    end

    context 'with invalid worksheet' do
      before do
        allow(QuizImporter).to receive(:import).with(
          spreadsheet: params[:spreadsheet],
          worksheet: params[:worksheet],
          course_code: course_code
        ).and_raise(QuizImporter::LoadWorksheetError, 'Invalid worksheet')
      end

      it 'sets an error flash message' do
        action.call
        expect(flash[:error]).to include 'Invalid worksheet'
      end
    end
  end

  describe 'POST convert_submission' do
    subject(:action) { -> { post :convert_submission, params: } }

    let(:params) { {id: course_id} }

    before do
      request.env['HTTP_REFERER'] = 'http://test.host/where_i_came_from'
    end

    context 'as user' do
      it 'redirects' do
        action.call
        expect(response).to have_http_status :see_other
      end
    end

    context 'not logged in' do
      let(:user) { nil }

      it 'redirects' do
        action.call
        expect(response).to have_http_status :see_other
      end
    end

    context 'with quiz.submission.manage permission' do
      let(:permissions) { ['quiz.submission.manage', 'course.content.access'] }

      it 'is successful' do
        action.call
        expect(response).to redirect_to 'http://test.host/where_i_came_from'
      end

      context 'with submission and snapshot params' do
        let(:params) { {id: course_id, submission_id:, snapshot_id:} }

        it 'is successful' do
          action.call
          expect(response).to have_http_status :see_other
        end

        it 'sets a flash error message' do
          action.call
          expect(flash[:success]).to include 'Submission was successfully converted from existing snapshot!'
        end
      end
    end
  end

  describe '#submissions' do
    subject(:action) { -> { get :submissions, params:, format: } }

    let(:permissions) { ['course.content.access', 'quiz.submission.index'] }

    let(:format) { :html }
    let(:params) { {id: course_id} }

    context 'with html format' do
      it 'returns success' do
        action.call

        expect(response).to have_http_status :ok
      end
    end

    context 'with a user_id param' do
      let(:params) { {id: course_id, user_id: enroll_user_id} }
      let(:section) { create(:'course_service/section', course:) }
      let(:quiz) { create(:'quiz_service/quiz') }

      before do
        create(:'account_service/user', id: enroll_user_id)
        create(:'course_service/item', :homework, section:, content_id: quiz.id, title: 'Homework 1')

        Stub.request(:quiz, :get, "/quizzes/#{quiz.id}")
          .to_return Stub.json(quiz.decorate.as_json(api_version: 1))
        Stub.request(
          :quiz, :get, '/user_quiz_attempts',
          query: {user_id: enroll_user_id, quiz_id: quiz.id}
        ).to_return Stub.json({additional_attempts: 0, attempts: 0})
      end

      it 'lists the homework submissions for the user' do
        action.call

        expect(response).to have_http_status :ok
        expect(assigns(:homework_submissions)).to contain_exactly(
          a_hash_including(title: "#{section.title}/Homework 1", quiz_id: quiz.id)
        )
      end
    end

    context 'with json format' do
      let(:format) { :json }

      let(:submission) do
        create(:'quiz_service/quiz_submission',
          id: submission_id, course_id: course_id, user_id: user_id)
      end

      it 'returns submissions json file' do
        submission
        action.call

        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to include('application/json')
        expect(response.headers['Content-Disposition']).to include('submissions.json')

        body = response.parsed_body

        expect(body).to eq([
          {
            'quiz_id' => submission.quiz_id,
            'submission_id' => submission.id,
            'user_name' => user.display_name,
            'user_email' => user.primary_email.address,
            'submitted_at' => submission.quiz_submission_time,
            'grade' => submission.fudge_points,
          },
        ])
      end

      context 'with more submissions than fit on a single page' do
        let(:submission_count) { 35 }

        before do
          create_list(:'quiz_service/quiz_submission', submission_count, course_id:)
        end

        it 'returns all matching submissions instead of only the first page' do
          action.call

          expect(response.parsed_body.size).to eq(submission_count)
        end
      end
    end

    context 'without permission' do
      let(:permissions) { ['course.content.access'] }

      it 'redirects' do
        action.call
        expect(response).to have_http_status :see_other
      end
    end
  end
end
