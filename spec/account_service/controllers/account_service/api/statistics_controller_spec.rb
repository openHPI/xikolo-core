# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::StatisticsController, type: :controller do
  subject(:response) { get :show }

  include_context 'account_service API controller'

  before { create_list(:'account_service/user', 5) }

  it { is_expected.to have_http_status :ok }

  context 'filter confirmed users' do
    subject(:json) { JSON.parse(response.body) }

    before { create_list(:'account_service/user', 5, :unconfirmed) }

    it { is_expected.to include 'confirmed_users' => 5 }
  end

  context 'unconfirmed users' do
    subject(:json) { JSON.parse(response.body) }

    before { create_list(:'account_service/user', 7, :unconfirmed) }

    it { is_expected.to include 'unconfirmed_users' => 7 }
  end

  context 'recent users' do
    subject(:json) { JSON.parse(response.body) }

    before { create_list(:'account_service/user', 5, created_at: 2.days.ago) }

    it { is_expected.to include 'confirmed_users' => 10 }
    it { is_expected.to include 'confirmed_users_last_day' => 5 }
  end

  context 'last week users' do
    subject(:json) { JSON.parse(response.body) }

    before do
      create_list(:'account_service/user', 5, created_at: 2.days.ago)
      create_list(:'account_service/user', 5, created_at: 9.days.ago)
    end

    it { is_expected.to include 'confirmed_users' => 15 }
    it { is_expected.to include 'confirmed_users_last_7days' => 10 }
  end

  context 'deleted users' do
    subject(:json) { JSON.parse(response.body) }

    before { create_list(:'account_service/user', 2, :archived) }

    it { is_expected.to include 'confirmed_users' => 5 }
    it { is_expected.to include 'users_deleted' => 2 }
  end
end
