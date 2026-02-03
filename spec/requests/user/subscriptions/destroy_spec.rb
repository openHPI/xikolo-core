# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Subscription: Destroy', type: :request do
  subject(:destroy_subscription) { post "/subscriptions/unsubscribe/#{question_resource['id']}", headers: }

  let(:question_resource) { build(:'pinboard:question', user_id: user.id) }
  let(:subscription) { build(:'pinboard:subscription', user_id: user.id, question_id: question_resource['id']) }
  let(:user) { create(:user) }

  before do
    stub_user_request(id: user.id)

    Stub.request(
      :pinboard, :get, '/subscriptions',
      query: {
        question_id: question_resource['id'],
        user_id: question_resource['user_id'],
      }
    ).to_return Stub.json([subscription])
    Stub.request(
      :pinboard, :delete, "/subscriptions/#{subscription['id']}"
    ).to_return Stub.json([subscription])
  end

  context 'as anonymous user' do
    it 'redirects to login page' do
      expect(destroy_subscription).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'deletes the subscription' do
      expect(destroy_subscription).to redirect_to 'http://www.example.com/preferences'
      expect(request.flash[:success].first).to eq 'Succesfully unfollowed the topic.'
    end
  end
end
