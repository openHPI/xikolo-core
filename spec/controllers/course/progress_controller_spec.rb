# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressController, type: :controller do
  subject { response }

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:other_user_id) { '00000001-3100-4444-9999-000000000002' }
  let(:course_id) { '00000001-636e-4444-9999-000000000044' }
  let(:course_code) { 'the_course' }
  let(:action) { -> { get :show, params: {course_id:} } }
  let(:request_context_id) { course_context_id }

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}',
      user_url: '/users/{id}'
    )
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      sections_url: '/sections',
      progresses_url: '/progresses'
    )

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      status: 'active',
      course_code:,
      title: 'Test Course',
      context_id: course_context_id,
    })
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:, learning_evaluation: 'true'}
    ).to_return Stub.json([
      {
        course_id:,
        certificates: [],
      },
    ])
  end

  describe 'show' do
    context 'as anonymous user' do
      before { action.call }

      it { is_expected.to redirect_to(course_url(course_code)) }

      it 'sets a flash error message' do
        expect(flash[:error]).to include 'Please log in to proceed.'
      end
    end

    context 'as logged in user without enrollment for current course' do
      before do
        stub_user id: user_id, language: 'en'
        action.call
      end

      it { is_expected.to redirect_to(course_url(course_code)) }

      it 'sets a flash error message' do
        expect(flash[:error].first).to eq I18n.t(:'flash.error.not_enrolled')
      end
    end

    context 'as logged in and enrolled' do
      before do
        stub_user id: user_id, language: 'en', permissions: ['course.content.access.available']

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id:},
        ])
        Stub.request(
          :course, :get, '/progresses',
          query: {course_id:, user_id:}
        ).to_return Stub.json([])
      end

      it 'responds with a valid html page' do
        action.call
        expect(response).to have_http_status :ok
        expect(assigns(:course_progress)).to be_a(Course::ProgressPresenter)
      end
    end

    context 'as course admin and different user_id' do
      render_views

      let(:action) do
        lambda do
          get :show, params: {course_id:, user_id: other_user_id}
        end
      end

      let(:course) { build(:'course:course', id: course_id) }
      let(:section) { build(:'course:section', course:) }
      let(:video) { build(:'course:item', :video, section:) }

      let(:progresses) do
        [
          {
            resource_id: section['id'],
            kind: 'section',
            visits: {
              total: 1,
              user: 0,
              percentage: 0,
            },
            available: true,
            items: [video],
          },
          {
            resource_id: course_id,
            kind: 'course',
          },
        ]
      end

      let!(:user_progress_statistic) do
        Stub.request(
          :course, :get, '/progresses',
          query: {course_id:, user_id: other_user_id}
        ).to_return Stub.json(progresses)
      end

      before do
        stub_user id: user_id, language: 'en', permissions: ['course.course.teaching', 'course.content.access.available']

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: other_user_id, course_id:, learning_evaluation: 'true'}
        ).to_return Stub.json([
          {
            course_id:,
            certificates: [],
          },
        ])
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id:},
        ])
        Stub.request(
          :account, :get, "/users/#{other_user_id}"
        ).to_return Stub.json({id: other_user_id})
      end

      it 'loads progress for requested user' do
        action.call
        expect(user_progress_statistic).to have_been_requested
      end

      it 'renders a proper progress page' do
        action.call
        expect(response.body).to include 'Progress | Test Course | Xikolo'

        video_id = UUID4.try_convert(video['id']).to_s(format: :base62)
        expect(response.body).to include "<a class=\"video\" href=\"/courses/#{course_code}/items/#{video_id}\">"
      end
    end

    context 'as no course admin and different user_id' do
      let(:params) do
        {course_id:, user_id: other_user_id}
      end

      let(:action) do
        -> { get :show, params: }
      end

      let!(:user_progress_statistic) do
        Stub.request(
          :course, :get, '/progresses',
          query: {course_id:, user_id:}
        ).to_return Stub.json([])
      end

      before do
        stub_user id: user_id, language: 'en', permissions: ['course.content.access.available']

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id:},
        ])
        Stub.request(
          :course, :get, '/sections',
          query: {course_id:}
        ).to_return Stub.json([])
      end

      it 'loads progress for current, not requested user' do
        action.call
        expect(user_progress_statistic).to have_been_requested
      end
    end
  end
end
