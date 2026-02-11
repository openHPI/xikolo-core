# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Role, type: :model do
  let(:role) { create(:'account_service/role') }
  let(:context) { create(:'account_service/context') }
  let(:principal) { create(:'account_service/user') }

  describe '.permissions' do
    subject { described_class.permissions principal:, context: }

    context 'with no granted roles' do
      it { is_expected.to match_array [] }
    end

    context 'with multiple granted roles' do
      let(:roles) { create_list(:'account_service/role', 4) }

      before do
        create(:'account_service/grant', principal:, role: roles[1], context:)
        create(:'account_service/grant', principal:, role: roles[2], context: AccountService::Context.root)

        # Create some other grants that should NOT be included
        create(:'account_service/grant', principal: create(:'account_service/user'), role: roles[0], context:)
        create(:'account_service/grant', principal: create(:'account_service/user'), role: roles[3], context: AccountService::Context.root)
      end

      it { is_expected.to match_array roles[1].permissions + roles[2].permissions }
    end

    context 'with group' do
      let(:role) { create(:'account_service/role') }
      let(:group) { create(:'account_service/group') }

      before do
        create(:'account_service/membership', user: principal, group:)
        create(:'account_service/grant', principal: group, role:, context:)
      end

      it { is_expected.to match_array role.permissions }
    end

    context 'with all users group' do
      let(:role) { create(:'account_service/role') }

      before do
        create(:'account_service/grant', principal: AccountService::Group.all_users, role:, context:)
      end

      it { is_expected.to match_array role.permissions }
    end

    context 'with client application' do
      let(:roles) { create_list(:'account_service/role', 4) }
      let(:principal) { create(:'account_service/client_application') }

      before do
        create(:'account_service/grant', principal:, role: roles[1], context:)
        create(:'account_service/grant', principal:, role: roles[2], context: AccountService::Context.root)

        # Create some other grants that should NOT be included
        create(:'account_service/grant', principal: create(:'account_service/client_application'), role: roles[0], context:)
        create(:'account_service/grant', principal: create(:'account_service/client_application'), role: roles[3], context: AccountService::Context.root)
      end

      it { is_expected.to match_array roles[1].permissions + roles[2].permissions }
    end
  end

  describe '.with_permissions' do
    subject(:result) { AccountService::Role.with_permissions(permission) }

    context 'with single permission' do
      let(:permission) { 'test.permission' }
      let(:roles) { AccountService::Role.all[1..2] }

      before do
        AccountService::Role.destroy_all
        create(:'account_service/role')
        create(:'account_service/role', permissions: ['test.permission'])
        create(:'account_service/role', permissions: ['a', 'test.permission', 'b'])
        create(:'account_service/role')
      end

      it 'returns matching roles' do
        expect(result).to match_array roles
      end
    end

    context 'with multiple permissions' do
      let(:permission) { ['test.p1', 'test.p2'] }
      let(:roles) { AccountService::Role.all[3] }

      before do
        AccountService::Role.destroy_all
        create(:'account_service/role')
        create(:'account_service/role', permissions: ['test.p1'])
        create(:'account_service/role', permissions: ['test.p2'])
        create(:'account_service/role', permissions: ['test.p1', 'test.p2'])
        create(:'account_service/role')
      end

      it 'returns matching roles' do
        expect(result).to match_array roles
      end
    end
  end
end
