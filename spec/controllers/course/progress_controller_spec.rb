# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressController, type: :controller do
  subject { response }

  let(:user) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active, course_code:, id: course_id, title: 'Test Course') }
  let(:course_id) { '00000001-636e-4444-9999-000000000044' }
  let(:course_code) { 'the_course' }
  let(:action) { -> { get :show, params: {course_id:} } }
  let(:course_context) { AccountService::Context.root }

  before do
    course
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id:, learning_evaluation: 'true'}
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
        sign_in user: user
        action.call
      end

      it { is_expected.to redirect_to(course_url(course_code)) }

      it 'sets a flash error message' do
        expect(flash[:error].first).to eq I18n.t(:'flash.error.not_enrolled')
      end
    end

    context 'as logged in and enrolled user' do
      render_views

      before do
        sign_in(user: user, permissions: ['course.content.access.available'])

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: user.id, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id: user.id},
        ])
        Stub.request(
          :course, :get, '/progresses',
          query: {course_id:, user_id: user.id}
        ).to_return Stub.json([])
      end

      it 'renders the empty progress page' do
        action.call
        expect(response).to have_http_status :ok
        expect(response.body).to include 'Progress | Test Course'
        expect(response.body).to include 'here are no items yet, so we cannot show you any progress now. Come back later.'
      end
    end

    context 'as course admin masquerading as another user, i.e. with different user ID' do
      render_views

      let(:action) do
        lambda do
          get :show, params: {course_id:, user_id: other_user.id}
        end
      end

      let(:course) { create(:'course_service/course', id: course_id, course_code:, title: 'Test Course') }
      let(:section) { build(:'course:section', course_id: course.id) }
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
          query: {course_id:, user_id: other_user.id}
        ).to_return Stub.json(progresses)
      end

      before do
        other_user
        sign_in(user: user, permissions: ['course.course.teaching', 'course.content.access.available'])

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: other_user.id, course_id:, learning_evaluation: 'true'}
        ).to_return Stub.json([
          {
            course_id:,
            certificates: [],
          },
        ])
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: user.id, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id: user.id},
        ])
        Stub.request(
          :account, :get, "/users/#{other_user.id}"
        ).to_return Stub.json(other_user.decorate.as_json)
      end

      it 'loads progress for requested user' do
        action.call
        expect(user_progress_statistic).to have_been_requested
      end

      it 'renders the progress page with a linked item' do
        action.call
        expect(response.body).to include 'My learning progress'

        video_id = UUID4.try_convert(video['id']).to_s(format: :base62)
        expect(Capybara.string(response.body))
          .to have_css "a[data-testid='item-card'][href='/learn/#{course_code}/items/#{video_id}']", visible: :all
      end
    end

    context 'as no course admin and different user ID' do
      let(:params) do
        {course_id:, user_id: other_user.id}
      end

      let(:action) do
        -> { get :show, params: }
      end

      let!(:user_progress_statistic) do
        Stub.request(
          :course, :get, '/progresses',
          query: {course_id:, user_id: user.id}
        ).to_return Stub.json([])
      end

      before do
        sign_in(user: user, permissions: ['course.content.access.available'])

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: user.id, course_id:}
        ).to_return Stub.json([
          {course_id:, user_id: user.id},
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
