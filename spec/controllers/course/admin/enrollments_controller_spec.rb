# frozen_string_literal: true

require 'spec_helper'

describe Course::Admin::EnrollmentsController, type: :controller do
  let(:user) { create(:'account_service/user') }
  let(:permissions) { [] }
  let(:course) { create(:'course_service/course') }

  before do
    sign_in(user: user, permissions:)
  end

  describe 'DELETE destroy' do
    subject(:delete_enrollment) { delete :destroy, params: }

    let(:params) { {course_id: course['id'], user_id: user.id} }
    let!(:enrollment_delete_stub) do
      Stub.request(:course, :delete, '/enrollments/123')
    end

    before do
      Stub.request(
        :course, :get, '/enrollments',
        query: hash_including(user_id: user.id, course_id: course['id'])
      ).to_return Stub.json([{url: '/course_service/enrollments/123'}])
    end

    context 'without permission' do
      it { expect(delete_enrollment).to redirect_to "/learn/#{course['course_code']}" }
    end

    context 'with permission' do
      let(:permissions) { %w[course.enrollment.delete course.content.access] }

      it 'unenrolls the user by deleting the corresponding enrollment' do
        expect(delete_enrollment).to redirect_to "/learn/#{course['id']}/enrollments"
        expect(flash[:notice]).to include 'User has been unenrolled successfully.'
        expect(enrollment_delete_stub).to have_been_requested
      end
    end
  end

  describe 'POST create' do
    subject(:create_enrollment) { post :create, params: }

    let(:params) { {} }
    let(:enrollments) { [] }
    let!(:enrollment_stub) do
      Stub.request(
        :course, :post, '/enrollments',
        body: hash_including(user_id: user.id, course_id: course['id'])
      ).to_return Stub.json({course_id: course['id'], user_id: user.id})
    end

    before do
      Stub.request(
        :course, :get, '/enrollments',
        query: hash_including(user_id: user.id, course_id: course['id'])
      ).to_return Stub.json(enrollments)
    end

    context 'without permission' do
      let(:params) { {course_id: course['id']} }

      it { expect(create_enrollment).to redirect_to "/learn/#{course['course_code']}" }
    end

    context 'with permission' do
      let(:permissions) { %w[course.enrollment.create course.content.access] }

      context 'without user ID' do
        let(:params) { {course_id: course['id']} }

        it 'responds wth an error' do
          expect(create_enrollment).to redirect_to "/learn/#{course['id']}/enrollments"
          expect(flash[:error]).to include 'Missing user ID. Please select a user before enrolling.'
          expect(enrollment_stub).not_to have_been_requested
        end
      end

      context 'with user ID' do
        let(:params) { {course_id: course['id'], user_id: user.id} }

        it 'enrolls the user (via corresponding request to xi-course)' do
          expect(create_enrollment).to redirect_to "/learn/#{course['id']}/enrollments"
          expect(flash[:notice]).to include 'User has been enrolled successfully.'
          expect(enrollment_stub).to have_been_requested
        end
      end

      context 'when already enrolled to the course' do
        let(:params) { {course_id: course['id'], user_id: user.id} }
        let(:enrollments) { [{user_id: user.id, course_id: course['id']}] }

        it 'indicates that the user is already enrolled' do
          expect(create_enrollment).to redirect_to "/learn/#{course['id']}/enrollments"
          expect(flash[:notice]).to include 'You are already enrolled to this course.'
          expect(enrollment_stub).not_to have_been_requested
        end
      end
    end
  end
end
