# frozen_string_literal: true

require 'spec_helper'

describe 'Grants: Create', type: :request do
  subject(:resource) { api.rel(:grants).post(data).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:role) { create(:'account_service/role', :with_name) }
  let(:group) { create(:'account_service/group') }
  let(:context) { create(:'account_service/context') }

  context 'on groups globally' do
    let(:data) { {group: group.name, role: role.name, context: 'root'} }

    it 'responds with a created resource' do
      expect(resource).to respond_with :created
    end

    it 'responds with a follow location to created resource' do
      expect(resource.follow).to eq account_service.grant_url(AccountService::Grant.last)
    end

    it 'creates database record' do
      expect { resource }.to change(AccountService::Grant, :count).by(1)
    end

    it 'saves the provided data' do
      resource
      grant = AccountService::Grant.last
      expect(grant.context).to eq AccountService::Context.root
      expect(grant.role).to eq role
      expect(grant.principal).to eq group
    end

    context 'with previously created grant' do
      let!(:grant) do
        create(:'account_service/grant', principal: group, role:, context: AccountService::Context.root)
      end

      it 'responds normally' do
        expect(resource).to respond_with :ok
      end

      it 'responds with a follow location to existing resource' do
        expect(resource.follow).to eq account_service.grant_url(grant)
      end

      it 'does not create a database record' do
        expect { resource }.not_to change(AccountService::Grant, :count)
      end
    end

    context 'on xikolo.admins group' do
      before do
        AccountService::Group.find_by!(name: 'xikolo.admins').destroy!
      end

      let(:data) { {group: 'xikolo.admins', role: role.name, context: 'root'} }

      it 'responds with a created resource' do
        expect(resource).to respond_with :created
      end

      it 'responds with a follow location to created resource' do
        expect(resource.follow).to eq account_service.grant_url(AccountService::Grant.last)
      end

      it 'creates database record' do
        expect { resource }.to change(AccountService::Grant, :count).by(1)
      end

      it 'creates the xikolo.admin group on the fly' do
        expect { resource }.to change(AccountService::Group, :count).by(1)
      end

      it 'saves the provided data' do
        resource
        grant = AccountService::Grant.last
        expect(grant.context).to eq AccountService::Context.root
        expect(grant.role).to eq role
        expect(grant.principal).to eq AccountService::Group.administrators
      end
    end
  end

  context 'on groups on specific context' do
    let(:data) { {group: group.name, role: role.name, context: context.id} }

    it 'responds with a created resource' do
      expect(resource).to respond_with :created
    end

    it 'responds with a follow location to created resource' do
      expect(resource.follow).to eq account_service.grant_url(AccountService::Grant.last)
    end

    it 'creates database record' do
      expect { resource }.to change(AccountService::Grant, :count).by(1)
    end

    it 'saves the provided data' do
      resource
      grant = AccountService::Grant.last
      expect(grant.context).to eq context
      expect(grant.role).to eq role
      expect(grant.principal).to eq group
    end

    context 'with previously created grant' do
      let!(:grant) do
        create(:'account_service/grant', principal: group, role:, context:)
      end

      it 'responds normally' do
        expect(resource).to respond_with :ok
      end

      it 'responds with a follow location to existing resource' do
        expect(resource.follow).to eq account_service.grant_url(grant)
      end

      it 'does not create a database record' do
        expect { resource }.not_to change(AccountService::Grant, :count)
      end
    end
  end
end
