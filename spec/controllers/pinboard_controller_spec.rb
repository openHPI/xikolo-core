# frozen_string_literal: true

require 'spec_helper'

describe PinboardController, type: :controller do
  let(:course_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { ['course.content.access.available'] }
  let(:request_context_id) { course_context_id }
  let(:course_params) do
    {
      id: course_id,
      title: 'Test Course',
      description: 'A Test Course.',
      status: 'active',
      course_code: 'test',
      start_date: DateTime.new(2013, 7, 12).iso8601,
      end_date: DateTime.new(2013, 8, 19).iso8601,
      abstract: 'Test Course abstract.',
      lang: 'en',
      context_id: course_context_id,
    }
  end

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({id: user_id})

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json(course_params)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id:}
    ).to_return Stub.json([])
  end

  describe 'index' do
    context 'not logged in' do
      it 'redirects' do
        get :index, params: {course_id:}
        expect(response).to have_http_status :found
      end
    end

    context 'logged in' do
      before { stub_user(id: user_id, permissions:) }

      context 'with disabled pinboard' do
        let(:course_params) { super().merge(pinboard_enabled: false) }

        it 'raises an error' do
          expect do
            get :index, params: {course_id:}
          end.to raise_error(AbstractController::ActionNotFound)
        end
      end
    end
  end
end
