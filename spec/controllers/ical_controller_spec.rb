# frozen_string_literal: true

require 'spec_helper'

describe IcalController, type: :controller do
  include IcalHelper

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:token) { 'abc' }
  let(:uuid) { UUID(user_id) }
  let(:permissions) { [] }
  let(:next_dates) { [] }
  let(:user) do
    {id: user_id,
     display_name: 'John Smith',
     language: 'en',
     permissions:}
  end

  before do
    stub_user features: {'ical_feed' => 'true'}

    Stub.request(
      :account, :post, '/tokens',
      body: hash_including(user_id:)
    ).to_return Stub.json({token:})
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json(user)

    Stub.request(
      :course, :get, '/next_dates',
      query: {user_id:}
    ).to_return Stub.json(next_dates)
  end

  describe '#index' do
    context 'with no params' do
      before { get :index }

      it 'answers with a error' do
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'with wrong user params' do
      it 'answers with a error' do
        expect do
          get :index, params: {u: 'abc', h: 'efg'}
        end.to raise_error(Status::NotFound)
      end
    end

    context 'with correct params' do
      before { get :index, params: {u: uuid, h: ical_hash(user_id)} }

      it 'answers success' do
        expect(response).to have_http_status :ok
      end
    end
  end
end
