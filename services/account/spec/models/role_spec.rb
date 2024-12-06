# frozen_string_literal: true

require 'spec_helper'

describe Role, type: :model do
  let(:role) { create(:role) }
  let(:context) { create(:context) }
  let(:principal) { create(:user) }

  describe '.permissions' do
    subject { Role.permissions principal:, context: }

    context 'with no granted roles' do
      it { is_expected.to match_array [] }
    end

    context 'with multiple granted roles' do
      let(:roles) { create_list(:role, 4) }

      before do
        create(:grant, principal:, role: roles[1], context:)
        create(:grant, principal:, role: roles[2], context: Context.root)

        # Create some other grants that should NOT be included
        create(:grant, principal: create(:user), role: roles[0], context:)
        create(:grant, principal: create(:user), role: roles[3], context: Context.root)
      end

      it { is_expected.to match_array roles[1].permissions + roles[2].permissions }
    end

    context 'with group' do
      let(:role) { create(:role) }
      let(:group) { create(:group) }

      before do
        create(:membership, user: principal, group:)
        create(:grant, principal: group, role:, context:)
      end

      it { is_expected.to match_array role.permissions }
    end

    context 'with all users group' do
      let(:role) { create(:role) }

      before do
        create(:grant, principal: Group.all_users, role:, context:)
      end

      it { is_expected.to match_array role.permissions }
    end

    context 'with client application' do
      let(:roles) { create_list(:role, 4) }
      let(:principal) { create(:client_application) }

      before do
        create(:grant, principal:, role: roles[1], context:)
        create(:grant, principal:, role: roles[2], context: Context.root)

        # Create some other grants that should NOT be included
        create(:grant, principal: create(:client_application), role: roles[0], context:)
        create(:grant, principal: create(:client_application), role: roles[3], context: Context.root)
      end

      it { is_expected.to match_array roles[1].permissions + roles[2].permissions }
    end
  end

  describe '.with_permissions' do
    subject(:result) { Role.with_permissions(permission) }

    context 'with single permission' do
      let(:permission) { 'test.permission' }
      let(:roles) { Role.all[1..2] }

      before do
        create(:role)
        create(:role, permissions: ['test.permission'])
        create(:role, permissions: ['a', 'test.permission', 'b'])
        create(:role)
      end

      it 'returns matching roles' do
        expect(result).to match_array roles
      end
    end

    context 'with multiple permissions' do
      let(:permission) { ['test.p1', 'test.p2'] }
      let(:roles) { Role.all[3] }

      before do
        create(:role)
        create(:role, permissions: ['test.p1'])
        create(:role, permissions: ['test.p2'])
        create(:role, permissions: ['test.p1', 'test.p2'])
        create(:role)
      end

      it 'returns matching roles' do
        expect(result).to match_array roles
      end
    end
  end
end
