# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Announcements: Index', type: :request do
  subject(:get_announcements) do
    get '/courses/my-course/announcements', headers:
  end

  let(:announcements_stub) do
    Stub.request(
      :news, :get, '/news',
      query: hash_including(language: 'en')
    ).to_return Stub.json([])
  end
  let(:headers) { {} }
  let(:course) { build(:'course:course') }

  before do
    Stub.service(:account, build(:'account:root'))

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/courses/my-course'
    ).to_return Stub.json(course)

    Stub.service(:news, news_index_url: '/news')
    announcements_stub
  end

  context 'for anonymous user' do
    it 'redirects to the course page' do
      get_announcements
      expect(response).to redirect_to course_url('my-course')
    end
  end

  context 'for logged-in user' do
    context 'not enrolled in course' do
      it 'redirects to the course page' do
        get_announcements
        expect(response).to redirect_to course_url('my-course')
      end
    end

    context 'enrolled in the course' do
      let!(:user) { stub_user_request permissions: ['course.content.access'] }
      let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: user[:id], course_id: course['id']}
        ).to_return Stub.json([{id: SecureRandom.uuid}])
        Stub.request(
          :course, :get, '/next_dates',
          query: hash_including(user_id: user[:id], course_id: course['id'])
        ).to_return Stub.json([])
      end

      it 'shows the course announcements page' do
        get_announcements
        expect(response).to be_successful
      end

      it 'requests all published course announcements only' do
        get_announcements
        expect(
          announcements_stub.with(
            query: {course_id: course['id'], published: 'true', language: 'en'}
          )
        ).to have_been_requested.once
      end

      context 'with permission to see all course announcements' do
        let(:user) do
          stub_user_request permissions: ['course.content.access', 'news.announcement.show']
        end

        it 'shows the course announcements page' do
          get_announcements
          expect(response).to be_successful
        end

        it 'requests all (including unpublished) course announcements' do
          get_announcements
          expect(
            announcements_stub.with(
              query: {course_id: course['id'], published: 'false', language: 'en'}
            )
          ).to have_been_requested.once
        end
      end
    end
  end
end
