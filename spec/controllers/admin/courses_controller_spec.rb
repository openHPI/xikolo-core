# frozen_string_literal: true

require 'spec_helper'

describe Admin::CoursesController, type: :controller do
  let(:user) { stub_user id: user_id, language: 'en', permissions: }
  let(:permissions) { [] }
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:course_code) { 'the-code' }

  around {|example| Timecop.freeze(&example) }

  before do
    user

    Stub.request(
      :course, :get, '/courses'
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      course_code:,
      context_id: course_context_id,
      created_at: DateTime.new(2015, 7, 12),
    })
    Stub.request(
      :course, :get, '/channels', query: {per_page: 250}
    ).to_return Stub.json([])
  end

  describe 'GET new' do
    context 'with permissions' do
      let(:permissions) { %w[course.course.create] }

      it 'shows a page' do
        get :new
        expect(response).to have_http_status :ok
      end
    end

    context 'without permissions' do
      it 'redirects to the start page' do
        get :new
        expect(response).to redirect_to root_url
      end
    end

    context 'user not logged in' do
      let(:user) { nil }

      it 'redirects the user' do
        get :new
        expect(response).to redirect_to root_url
      end
    end
  end

  describe 'PUT create' do
    subject { response }

    let(:request_context_id) { 'root' }
    let(:params) do
      {
        xikolo_course_course: {
          course_code:,
            teacher_ids: '',
        },
      }
    end
    let(:action) { -> { put :create, params: } }

    before do
      action.call
    end

    context 'as user' do
      it 'redirects the user' do
        expect(response).to redirect_to root_url
      end
    end
  end

  describe 'DELETE destroy' do
    subject { response }

    let(:action) { -> { delete :destroy, params: } }
    let(:request_context_id) { course_context_id }
    let(:params) { {id: course_id, course_code:} }

    before do
      Stub.request(
        :course, :get, "/courses/#{course_code}"
      ).to_return Stub.json({
        id: course_id,
        course_code:,
        self_url: "http://localhost:3000/course_service/courses/#{course_id}",
      })
      Stub.request(
        :course, :delete, "/courses/#{course_id}"
      ).to_return Stub.response(status: 202)
    end

    context 'as user' do
      it 'cannot access the page' do
        expect { action.call }.to raise_error(Status::NotFound)
      end
    end

    context 'with course.course.delete permission' do
      let(:permissions) { %w[course.course.delete course.content.access] }

      it 'answers with a page' do
        action.call
        expect(response).to have_http_status :found
      end

      it 'sets a flash notice message' do
        action.call
        expect(flash[:notice]).to include 'The course has been deleted.'
      end
    end
  end
end
