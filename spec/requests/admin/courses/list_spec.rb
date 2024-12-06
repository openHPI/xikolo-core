# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Courses: Index', type: :request do
  before do
    Stub.service(:course, build(:'course:root'))
  end

  describe 'published courses' do
    subject(:request) do
      get '/admin/courses', headers:
    end

    let(:headers) { {} }

    before do
      Stub.request(
        :course, :get, '/courses',
        query: {alphabetic: '1', groups: 'any'}
      ).to_return Stub.json([
        build(:'course:course', title: 'Course 1', status: 'active'),
        build(:'course:course', title: 'Course 2', status: 'archive'),
      ])
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :found
      end
    end

    context 'as logged in user' do
      let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
      let(:permissions) { [] }

      before { stub_user_request permissions: }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :found
      end

      context 'with permissions' do
        let(:permissions) { ['course.course.index'] }
        let(:page) { Capybara.string(response.body) }

        it 'lists all courses' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_content 'Course 1'
          expect(page).to have_content 'active'
          expect(page).to have_content 'Course 2'
          expect(page).to have_content 'archive'
        end
      end
    end
  end

  describe 'courses in preparation' do
    subject(:request) do
      get '/admin/courses?status=preparation', headers:
    end

    let(:headers) { {} }

    before do
      Stub.request(
        :course, :get, '/courses',
        query: {status: 'preparation', alphabetic: '1', groups: 'any'}
      ).to_return Stub.json([build(:'course:course', title: 'Course 1', status: 'preparation')])
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :found
      end
    end

    context 'as logged in user' do
      let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
      let(:permissions) { [] }

      before { stub_user_request permissions: }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :found
      end

      context 'with permissions' do
        let(:permissions) { ['course.course.index'] }
        let(:page) { Capybara.string(response.body) }

        it 'lists all courses in preparation' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_content 'Course 1'
          expect(page).to have_content 'Preparation'
        end
      end
    end
  end
end
