# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::PreferencesController, type: :controller do
  include_context 'account_service API controller'
  let(:user) { create(:'account_service/user') }

  describe '#show' do
    subject(:response) { get :show, params: {user_id: user.id} }

    it { is_expected.to have_http_status :ok }

    it 'responds with preferences as JSON' do
      expect(response.body).to eq PreferencesDecorator.new(user).to_json
    end
  end
end
