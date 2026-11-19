# frozen_string_literal: true

require 'spec_helper'

describe SessionHelper, type: :helper do
  subject(:ctx) do
    Struct.new(:session, :current_user, :request) do
      include SessionHelper
    end.new(session, current_user, request)
  end

  let(:current_user) { nil }

  describe '#logout' do
    let(:current_user) do
      CurrentUser::User.new(session: create(:'account_service/session'), context_id: 'root')
    end

    before do
      allow(request).to receive(:env).and_return({})
    end

    it 'removes the session resource' do
      ctx
      expect { ctx.logout }.to change(AccountService::Session, :count).by(-1)
    end
  end
end
