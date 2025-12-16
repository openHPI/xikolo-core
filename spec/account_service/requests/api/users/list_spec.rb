# frozen_string_literal: true

require 'spec_helper'

describe 'List users', type: :request do
  subject(:resource) { api.rel(:users).get(params).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:params) { {} }
  let!(:user) { create(:'account_service/user') }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with users' do
    expect(resource).to eq json([user])
  end

  context 'with anonymous users' do
    before do
      AccountService::User.anonymous # Force creation of anonymous user

      expect(AccountService::User.count).to eq 2
    end

    it 'does not list anonymous users by default' do
      expect(resource.pluck('id')).to eq [user.id]
    end
  end

  describe 'pagination' do
    before do
      AccountService::User.anonymous
      create_list(:'account_service/user', 25) # rubocop:disable FactoryBot/ExcessiveCreateList
      create_list(:'account_service/user', 2, :admin)
      create_list(:'account_service/user', 5, :archived)
    end

    let(:users) { AccountService::User.active.to_a }
    let(:params) { {per_page: 10} }

    it 'includes initial pagination header' do
      expect(resource.response.headers).to include 'X_TOTAL_COUNT' => '28'
      expect(resource.response.headers).to include 'X_TOTAL_PAGES' => '3'
    end

    it 'paginates user' do
      res = resource

      expect(res.size).to eq 10
      expect(res.as_json.map { it['id'] }).to eq users[0, 10].map(&:id)
      expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'

      res = res.rel(:next).get.value!

      expect(res.size).to eq 10
      expect(res.as_json.map { it['id'] }).to eq users[10, 10].map(&:id)
      expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'

      res = res.rel(:next).get.value!

      expect(res.size).to eq 8
      expect(res.as_json.map { it['id'] }).to eq users[20, 8].map(&:id)
      expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'
    end

    context 'with record UUID as page' do
      let(:params) { {per_page: 10, page: users[9].id} }

      it 'paginates user' do
        res = resource

        expect(res.size).to eq 10
        expect(res.as_json.map { it['id'] }).to eq users[10, 10].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'

        res = res.rel(:next).get.value!

        expect(res.size).to eq 8
        expect(res.as_json.map { it['id'] }).to eq users[20, 8].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'
      end
    end

    context 'with page numbers' do
      let(:params) { {per_page: 10, page: 1} }

      it 'paginates user' do
        res = resource

        expect(res.size).to eq 10
        expect(res.as_json.map { it['id'] }).to eq users[0, 10].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'

        res = api.rel(:users).get({**params, page: 2}).value!

        expect(res.size).to eq 10
        expect(res.as_json.map { it['id'] }).to eq users[10, 10].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'

        res = api.rel(:users).get({**params, page: 3}).value!

        expect(res.size).to eq 8
        expect(res.as_json.map { it['id'] }).to eq users[20, 8].map(&:id)
        expect(res.response.headers['X_TOTAL_COUNT']).to eq '28'
      end
    end
  end

  describe '?permission' do
    let(:permissions) { %w[permission0 permission1 permission2] }
    let(:role) { create(:'account_service/role', permissions:) }
    let(:permission) { 'permission1' }
    let(:params) { {permission:} }
    let(:user) { create(:'account_service/user') }

    before do
      create_list(:'account_service/user', 4)
      create_list(:'account_service/role', 5)
    end

    context 'with user grant' do
      before do
        create(:'account_service/grant', principal: user, role:)
      end

      it 'responds with 200 Ok' do
        expect(resource).to respond_with :ok
      end

      it 'responds with matching users resources' do
        expect(resource).to eq json([user])
      end
    end

    context 'with group grant' do
      let(:group) { create(:'account_service/group') }

      before do
        create(:'account_service/membership', user:, group:)
        create(:'account_service/grant', principal: group, role:)
      end

      it 'responds with 200 Ok' do
        expect(resource).to respond_with :ok
      end

      it 'responds with matching users resources' do
        expect(resource).to eq json([user])
      end
    end

    context 'with context' do
      let(:parent_context) { create(:'account_service/context') }
      let(:other_context) { create(:'account_service/context', parent: parent_context) }
      let(:context) { create(:'account_service/context', parent: parent_context) }
      let(:params) { {permission:, context:} }

      context 'with user grant' do
        context 'on given context' do
          before do
            create(:'account_service/grant', principal: user, role:, context:)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([user])
          end
        end

        context 'on parent context' do
          before do
            create(:'account_service/grant', principal: user, role:, context: parent_context)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([user])
          end
        end

        context 'on another context' do
          before do
            create(:'account_service/grant', principal: user, role:, context: other_context)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([])
          end
        end
      end

      context 'with group grant' do
        let(:group) { create(:'account_service/group') }

        before do
          create(:'account_service/membership', user:, group:)
        end

        context 'on given context' do
          before do
            create(:'account_service/grant', principal: group, role:, context:)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([user])
          end
        end

        context 'on parent context' do
          before do
            create(:'account_service/grant', principal: group, role:, context: parent_context)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([user])
          end
        end

        context 'on another context' do
          before do
            create(:'account_service/grant', principal: group, role:, context: other_context)
          end

          it 'responds with 200 Ok' do
            expect(resource).to respond_with :ok
          end

          it 'responds with matching users resources' do
            expect(resource).to eq json([])
          end
        end
      end
    end
  end
end
