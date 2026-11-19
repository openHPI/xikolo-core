# frozen_string_literal: true

require 'spec_helper'

describe Admin::CoursesController, type: :controller do
  let(:user) { create(:'account_service/user', id: user_id, language: 'en') }
  let(:permissions) { [] }
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:course_code) { 'the-code' }
  let(:course) { create(:'course_service/course', id: course_id, course_code:) }

  around {|example| Timecop.freeze(&example) }

  before do
    course
    sign_in(user: user, permissions:) if user

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
    let(:params) { {id: course_id, course_code:} }
    let(:course) { create(:'course_service/course', id: course_id, course_code:) }

    before do
      course
    end

    context 'as user' do
      it 'cannot access the page' do
        expect(action.call).to redirect_to course_url(course.course_code)
      end
    end

    context 'with course.course.delete permission' do
      let(:permissions) { %w[course.course.delete course.content.access] }

      it 'answers with a page' do
        pending 'CourseService::Course::Destroy calls destroy_context!' \
                'that is not implimented in account_service.' \
                'Destruction will work in production with a silent failure in ' \
                'the context destruction.'

        action.call

        expect(response).to have_http_status :see_other
      end

      it 'sets a flash notice message' do
        pending 'CourseService::Course::Destroy calls destroy_context!' \
                'that is not implimented in account_service.' \
                'Destruction will work in production with a silent failure in ' \
                'the context destruction.'

        action.call
        expect(flash[:notice]).to include 'The course has been deleted.'
      end
    end
  end
end
