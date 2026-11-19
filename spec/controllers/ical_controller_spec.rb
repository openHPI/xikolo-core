# frozen_string_literal: true

require 'spec_helper'

describe IcalController, type: :controller do
  include IcalHelper

  let(:uuid) { UUID(user.id) }
  let(:user) { create(:'account_service/user') }

  before do
    create(:'account_service/feature',
      owner: user,
      name: 'ical_feed',
      value: 'true',
      context: AccountService::Context.root)

    sign_in(user:)
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
      before { get :index, params: {u: uuid, h: ical_hash(user.id)} }

      it 'answers success' do
        expect(response).to have_http_status :ok
      end
    end
  end
end
