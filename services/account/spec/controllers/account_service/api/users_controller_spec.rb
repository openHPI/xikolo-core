# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::UsersController, type: :controller do
  include_context 'account_service API controller'
  let(:user) { create(:'account_service/user') }

  # test for side effects; we had an error declare ALL users as admin if
  # there exists an admin, so lets create one
  let!(:admin) { create(:'account_service/user', :admin) }

  describe 'GET #show' do
    subject(:response) { get :show, params: {id: user.id} }

    it { is_expected.to have_http_status :ok }

    describe '#headers' do
      subject { response.headers.to_h }

      it { is_expected.to include 'x-cache-xikolo' => 'shared' }
    end

    describe '#links' do
      subject(:links) { response.links }

      it 'includes link to the users email resources' do
        expect(links).to include url: user_emails_url(user), params: {rel: :emails}
      end
    end

    describe 'payload' do
      subject(:payload) { JSON.parse(response.body) }

      it { is_expected.not_to eq user.as_json }
      it { is_expected.to eq UserDecorator.new(user.reload).as_json }
      it { is_expected.to include 'affiliated' => false }
    end
  end

  describe 'PATCH #update' do
    subject(:response) { patch :update, params: }

    let(:params) { {id: user.id} }

    context 'with non-existent user' do
      let(:params) { {id: '5eb54d87-e282-46f5-98e1-e8e5b84d677f'} }

      it { is_expected.to have_http_status :not_found }
    end

    context 'with changed email' do
      let(:params) { {**super(), email: 'newemail@example.org'} }

      it { is_expected.to have_http_status :bad_request }

      describe 'payload error messages' do
        subject(:errors) { JSON.parse(response.body)['errors'] }

        it { is_expected.to include 'email' => ['read-only'] }
      end
    end

    context 'with affiliated: true' do
      subject(:payload) { JSON.parse(response.body) }

      let(:params) { {**super(), affiliated: true} }

      it { is_expected.to include 'affiliated' => true }
    end

    context 'with partial update' do
      subject(:payload) { JSON.parse(response.body) }

      let(:params) { {**super(), language: 'de'} }

      it { is_expected.to include 'language' => 'de' }
    end
  end

  describe 'PUT #update' do
    subject(:response) { put :update, params: }

    context 'with non-existent user' do
      let(:params) do
        {
          **attributes_for(:'account_service/user'),
          id: 'c3b2068a-9525-4d5c-9672-6e547a10f6ba',
          email: 'root@localhost',
        }
      end

      let(:user) { User.find 'c3b2068a-9525-4d5c-9672-6e547a10f6ba' }

      it { is_expected.to have_http_status :ok }

      it 'creates user record' do
        expect { response }.to change(User, :count).from(1).to(2)

        expect(user.id).to eq params[:id]
        expect(user.email).to eq params[:email]
        expect(user.full_name).to eq params[:full_name]
        expect(user.display_name).to eq params[:display_name]
      end

      describe '#headers' do
        subject { response.headers.to_h }

        it { is_expected.to include 'location' => user_url(user) }
      end

      describe 'payload' do
        subject(:payload) { JSON.parse(response.body) }

        it { is_expected.to eq UserDecorator.new(user).as_json }
      end
    end
  end

  describe 'GET #index' do
    subject(:response) { get :index, params: }

    let(:payload) { JSON.parse(response.body) }
    let(:params) { {} }

    it { is_expected.to be_successful }

    describe 'payload' do
      let!(:users) { create_list(:'account_service/user', 5) + [admin] }

      it { expect(payload.size).to eq users.size }

      it 'returns the correct users' do
        expect(payload).to match_array \
          users.map {|u| UserDecorator.new(u).as_json }
      end
    end

    describe 'archived' do
      subject(:ids) { payload.pluck('id') }

      let!(:users) { create_list(:'account_service/user', 10) + [admin] }
      let!(:ausers)  { create_list(:'account_service/user', 4, :archived) }

      it 'does not include archived users by default' do
        expect(ids).to match_array users.map(&:id)
      end

      context 'with invalid value' do
        let(:params) { {archived: 'xy'} }

        it 'does not include archived users' do
          expect(ids).to match_array users.map(&:id)
        end
      end

      context 'with empty value' do
        let(:params) { {archived: ''} }

        it 'does not include archived users' do
          expect(ids).to match_array users.map(&:id)
        end
      end

      context 'with true value' do
        let(:params) { {archived: 'true'} }

        it 'only includes archived users' do
          expect(ids).to match_array ausers.map(&:id)
        end
      end

      context 'with false value' do
        let(:params) { {archived: 'false'} }

        it 'does not include archived users' do
          expect(ids).to match_array users.map(&:id)
        end
      end

      context 'with include value' do
        let(:params) { {archived: 'include'} }

        it 'includes all users' do
          expect(ids).to match_array \
            users.map(&:id) + ausers.map(&:id)
        end
      end
    end

    describe 'confirmed' do
      subject(:ids) { payload.pluck('id') }

      let!(:users) { create_list(:'account_service/user', 10) + [admin] }
      let!(:uusers)  { create_list(:'account_service/user', 4, :unconfirmed) }

      it 'includes all users by default' do
        expect(ids).to match_array \
          users.map(&:id) + uusers.map(&:id)
      end

      context 'with empty value' do
        let(:params) { {confirmed: ''} }

        it 'includes all users' do
          expect(ids).to match_array users.map(&:id) + uusers.map(&:id)
        end
      end

      context 'with invalid value' do
        let(:params) { {confirmed: 'xy'} }

        it 'includes all users' do
          expect(ids).to match_array users.map(&:id) + uusers.map(&:id)
        end
      end

      context 'with true value' do
        let(:params) { {confirmed: 'true'} }

        it 'only includes confirmed users' do
          expect(ids).to match_array users.map(&:id)
        end
      end

      context 'with false value' do
        let(:params) { {confirmed: 'false'} }

        before do
          uusers[1].emails.update_all confirmed: nil
          uusers[3].emails.update_all confirmed: nil
        end

        it 'does not include confirmed users' do
          expect(ids).to match_array uusers.map(&:id)
        end
      end
    end

    describe 'id' do
      subject(:ids) { payload.pluck('id') }

      let!(:users) { create_list(:'account_service/user', 10) + [admin] }

      it 'includes all users by default' do
        expect(ids).to match_array \
          users.map(&:id)
      end

      context 'with empty id' do
        let(:params) { {id: ''} }

        it { expect(ids).to match_array users.map(&:id) }
      end

      context 'with single UUID' do
        let(:params) { {id: users[2].id} }

        it 'only includes confirmed users' do
          expect(ids).to contain_exactly(users[2].id)
        end
      end

      context 'with list of UUIDs' do
        let(:params) { {id: users[2..4].map(&:id).join(',')} }

        it 'does not include confirmed users' do
          expect(ids).to match_array users[2..4].map(&:id)
        end
      end
    end

    describe 'query' do
      subject(:ids) { payload.pluck('id') }

      let(:params) { {query: 'jack'} }
      let!(:users) { create_list(:'account_service/user', 10) }

      let!(:matches) do
        users[3].update! full_name: 'Jack'
        users[4].update! full_name: 'Jackson'
        users[5].update! display_name: 'Jacky James'
        users[6].emails.primary.take.update! address: 'jack.smith@example.de'
        users[3..6]
      end

      it 'matches on email, display name, and full name' do
        expect(ids).to match_array matches.map(&:id)
      end
    end

    describe 'query with underscore' do
      subject(:ids) { payload.pluck('id') }

      let(:params) { {query: 'jack_smith'} }
      let!(:users) { create_list(:'account_service/user', 10) }

      let!(:matches) do
        users[2].update! display_name: 'jackxsmith'
        users[5].update! display_name: 'jack_smith'
        users[6].emails.primary.take.update! address: 'jack_smith@example.de'
        users[5..6]
      end

      it 'matches on email' do
        expect(ids).to match_array matches.map(&:id)
      end
    end

    describe 'search by auth uid query' do
      before do
        create_list(:'account_service/user', 10)
      end

      let(:params) { {auth_uid: authorization.uid} }
      let(:authorization) do
        create(:'account_service/authorization', user:)
      end
      let(:payload) { JSON.parse(response.body) }

      it { is_expected.to have_http_status :ok }
      it { expect(payload.size).to eq 1 }

      it 'finds user via authorization uid' do
        expect(payload).to match [hash_including('id' => user.id)]
      end
    end
  end
end
