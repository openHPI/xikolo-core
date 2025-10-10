# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CourseSubscriptions', type: :request do
  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:course_id) { '00000001-3300-4444-9999-000000000001' }
  let(:course_subscription_id) { '00000005-3500-4444-9999-000000000001' }
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

  before do
    Stub.service(:account, build(:'account:root'))
    stub_user_request id: user_id

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({id: course_id, course_code: 'test'})

    Stub.service(:pinboard, build(:'pinboard:root'))
  end

  describe 'POST /course_subscriptions' do
    context 'when successful' do
      before do
        Stub.request(
          :pinboard, :post, '/course_subscriptions',
          body: hash_including(user_id:, course_id:)
        ).to_return Stub.json({id: course_subscription_id, user_id:, course_id:})
      end

      it 'creates a subscription and redirects back' do
        post course_subscriptions_path, params: {course_id:}, headers: headers.merge('HTTP_REFERER' => "/courses/#{course_id}/pinboard")
        expect(response).to have_http_status(:found)
        expect(response.headers['Location']).to include("/courses/#{course_id}/pinboard")
      end
    end

    context 'when creation fails' do
      before do
        Stub.request(
          :pinboard, :post, '/course_subscriptions',
          body: hash_including(user_id:, course_id:)
        ).to_return Stub.response(status: 500)
      end

      it 'raises an exception' do
        expect do
          post course_subscriptions_path, params: {course_id:}, headers: headers.merge('HTTP_REFERER' => "/courses/#{course_id}/pinboard")
        end.to raise_error(Restify::InternalServerError)
      end
    end
  end

  describe 'DELETE /course_subscriptions/:id' do
    context 'when successful' do
      before do
        Stub.request(:pinboard, :delete, "/course_subscriptions/#{course_subscription_id}")
          .to_return Stub.response(status: 204)
      end

      it 'destroys a subscription and redirects back' do
        delete course_subscription_path(course_subscription_id), params: {course_id:}, headers: headers.merge('HTTP_REFERER' => "/courses/#{course_id}/pinboard")
        expect(response).to have_http_status(:found)
        expect(response.headers['Location']).to include("/courses/#{course_id}/pinboard")
      end
    end

    context 'when deletion fails' do
      before do
        Stub.request(:pinboard, :delete, "/course_subscriptions/#{course_subscription_id}")
          .to_return Stub.response(status: 500)
      end

      it 'raises an exception' do
        expect do
          delete course_subscription_path(course_subscription_id), params: {course_id:}, headers: headers.merge('HTTP_REFERER' => "/courses/#{course_id}/pinboard")
        end.to raise_error(Restify::InternalServerError)
      end
    end
  end
end
