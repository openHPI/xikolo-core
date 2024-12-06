# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Enrollments: Create', type: :request do
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:permissions) { [] }
  let(:params) { {course_id: course['id']} }
  let(:course) { build(:'course:course') }
  let(:create_stub) do
    Stub.request(
      :course, :post, '/enrollments',
      body: hash_including(user_id:, course_id: course['id'])
    ).to_return Stub.json(
      build(:'course:enrollment', user_id:, course_id: course['id'])
    )
  end

  before do
    stub_user_request(id: user_id, permissions:)
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course['id']}"
    ).to_return Stub.json(course)
    create_stub
  end

  describe 'via POST' do
    subject(:action) do
      post '/enrollments', params:, headers:
    end

    context 'when the user is not yet enrolled' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json([])
      end

      it 'redirects to the course details page' do
        action
        expect(response).to redirect_to course_path course['course_code']
      end

      it 'creates an enrollment' do
        action
        expect(create_stub).to have_been_requested
      end
    end

    context 'when the user is already enrolled' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json(
          build(:'course:enrollment', user_id:, course_id: course['id'])
        )
      end

      it 'redirects to the course content' do
        action
        expect(response).to redirect_to course_resume_path course['course_code']
      end

      it 'does not create another enrollment' do
        action
        expect(create_stub).not_to have_been_requested
      end
    end

    context 'when the server does not accept the enrollment' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json(error_response, status: 422)
      end

      context 'because an enrollment already exists' do
        let(:error_response) { {errors: {user_id: ['already enrolled']}} }

        it 'redirects to the course content' do
          action
          expect(response).to redirect_to course_resume_path course['course_code']
        end
      end

      context 'because the course is restricted to other user groups' do
        let(:error_response) { {errors: {base: %w[access_restricted]}} }

        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to "/courses/#{course['course_code']}"
        end
      end

      context 'because the course prerequisites are not fulfilled' do
        let(:error_response) { {errors: {base: %w[prerequisites_unfulfilled]}} }

        it 'informs the user about not fulfilled prerequisites' do
          action
          expect(flash[:error].first).to eq 'You have not yet fulfilled the prerequisites for participation in this course.'
          expect(flash[:error].length).to eq 1
        end

        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to "/courses/#{course['course_code']}"
        end
      end
    end

    context 'for an invite-only course' do
      let(:course) { build(:'course:course', invite_only: true) }

      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json([])
      end

      context 'as a regular user' do
        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to course_path course['course_code']
        end

        it 'does not create an enrollment' do
          action
          expect(create_stub).not_to have_been_requested
        end
      end

      context 'with teaching rights' do
        let(:permissions) { ['course.content.access'] }

        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to "/courses/#{course['course_code']}"
        end

        it 'creates an enrollment' do
          action
          expect(create_stub).to have_been_requested
        end
      end
    end

    context 'without course ID' do
      let(:params) { {} }

      it 'responds with 404 Not Found' do
        expect { action }.to raise_error AbstractController::ActionNotFound
      end
    end
  end

  # HACK: Enrollment via GET is allowed as well
  describe 'via GET' do
    subject(:action) do
      get '/enrollments', params:, headers:
    end

    context 'when the user is not yet enrolled' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json([])
      end

      it 'redirects to the course details page' do
        action
        expect(response).to redirect_to "/courses/#{course['course_code']}"
      end

      it 'creates an enrollment' do
        action
        expect(create_stub).to have_been_requested
      end
    end

    context 'without course ID' do
      let(:params) { {} }

      it 'responds with 404 Not Found' do
        expect { action }.to raise_error AbstractController::ActionNotFound
      end
    end
  end
end
