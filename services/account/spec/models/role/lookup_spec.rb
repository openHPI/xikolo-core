# frozen_string_literal: true

require 'spec_helper'

describe Role, '.lookup', type: :model do
  let(:roles) { create_list(:role, 4) }
  let(:context) { create(:context) }
  let(:request_context) { context }
  let(:grant_context) { context }

  describe '.lookup' do
    subject(:results) do
      Role.lookup(principal:, context: request_context)
    end

    shared_examples 'context:inheritance' do
      context 'with requesting a child context' do
        let(:request_context) { create(:context, parent: grant_context) }

        it 'contains exactly the granted roles' do
          expect(results).to match_array granted_roles
        end
      end

      context 'with requesting a parent context' do
        let(:grant_context) { create(:context, parent: request_context) }

        it 'does not contain the granted roles' do
          expect(results).not_to include granted_roles
        end
      end
    end

    context 'with group principal' do
      let(:principal) { create(:group) }
      let(:granted_roles) { roles.slice(1, 1) }

      before do
        create(:grant,
          principal:, role: roles[1], context: grant_context)
      end

      it 'returns group roles' do
        expect(results).to match_array granted_roles
      end

      it_behaves_like 'context:inheritance'
    end

    context 'with user principal' do
      let(:principal) { create(:user) }
      let(:granted_roles) { roles.slice(1, 1) }

      before do
        create(:grant,
          principal:, role: roles[1], context: grant_context)
      end

      it 'returns group roles' do
        expect(results).to match_array granted_roles
      end

      it_behaves_like 'context:inheritance'

      context 'with group membership' do
        let(:groups) { create_list(:group, 4) }
        let(:granted_roles) { [roles[1], roles[2]] }

        before do
          create(:grant,
            principal: groups[1], role: roles[2], context: grant_context)

          principal.groups << groups[1]
        end

        it_behaves_like 'context:inheritance'
      end

      context 'with multiple group memberships' do
        let(:groups) { create_list(:group, 4) }
        let(:granted_roles) { [roles[1], roles[2], roles[3]] }

        before do
          create(:grant,
            principal: groups[1], role: roles[2], context: grant_context)
          create(:grant,
            principal: groups[2], role: roles[3], context: grant_context)

          principal.groups << groups[1]
          principal.groups << groups[2]
        end

        it_behaves_like 'context:inheritance'
      end

      context 'with multiple group memberships on different' do
        let(:groups) { create_list(:group, 4) }
        let(:granted_roles) { [roles[1], roles[2], roles[3]] }

        before do
          create(:grant,
            principal: groups[1], role: roles[2], context: grant_context)
          create(:grant,
            principal: groups[2], role: roles[3], context: Context.root)

          principal.groups << groups[1]
          principal.groups << groups[2]
        end

        it_behaves_like 'context:inheritance'
      end

      context 'with special group grant' do
        let(:granted_roles) { [roles[1], roles[2]] }

        before do
          create(:grant,
            principal: group, role: roles[2], context: grant_context)
        end

        context 'all users group' do
          let(:group) { Group.all_users }

          it_behaves_like 'context:inheritance'
        end

        context 'active users group' do
          let(:group) { Group.active_users }

          it_behaves_like 'context:inheritance'
        end

        context 'confirmed users group' do
          let(:group) { Group.confirmed_users }

          it_behaves_like 'context:inheritance'
        end

        context 'unconfirmed users group' do
          let(:group) { Group.unconfirmed_users }

          before do
            principal.update! confirmed: false
          end

          it_behaves_like 'context:inheritance'
        end

        context 'archived users group' do
          let(:group) { Group.archived_users }

          before do
            principal.update! archived: true
          end

          it_behaves_like 'context:inheritance'
        end
      end
    end
  end
end
