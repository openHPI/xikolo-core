# frozen_string_literal: true

RSpec.shared_examples 'shared:permissions' do
  let(:roles) { create_list(:role, 4) }
  let(:groups) { create_list(:group, 4) }

  let(:context) { create(:context) }
  let(:child_context) { create(:context, parent: context) }
  let(:request_context) { child_context }

  before do
    user.groups << groups[1]
    user.groups << groups[2]
  end

  context 'with user grant' do
    before do
      create(:grant, principal: user, role: roles[1], context:)
    end

    it 'matches permissions' do
      expect(subject).to match_array roles[1].permissions
    end

    context 'with context inheritance' do
      before do
        create(:grant,
          principal: user, role: roles[2], context: child_context)
      end

      it 'matches permissions' do
        expect(subject).to match_array \
          roles[1].permissions + roles[2].permissions
      end
    end
  end

  describe 'group grants' do
    before do
      create(:grant, principal: groups[1], role: roles[1], context:)
    end

    it 'responds with correct permissions' do
      expect(subject).to match_array roles[1].permissions
    end

    context 'with multiple groups' do
      before do
        create(:grant,
          principal: groups[2], role: roles[2], context:)
      end

      it 'matches permissions' do
        expect(subject).to match_array \
          roles[1].permissions + roles[2].permissions
      end
    end

    context 'with context inheritance' do
      before do
        create(:grant,
          principal: groups[1], role: roles[2], context: child_context)
      end

      it 'responds with correct permissions' do
        expect(subject).to match_array \
          roles[1].permissions + roles[2].permissions
      end
    end
  end

  describe 'all user grants' do
    before do
      create(:grant, principal: Group.all_users, role: roles[3])
    end

    it 'responds with correct permissions' do
      expect(subject).to match_array roles[3].permissions
    end
  end

  describe 'active user grants' do
    before do
      create(:grant, principal: Group.active_users, role: roles[3])
    end

    it 'responds with correct permissions' do
      expect(subject).to match_array roles[3].permissions
    end
  end

  describe 'confirmed user grants' do
    before do
      create(:grant, principal: Group.confirmed_users, role: roles[3])
    end

    it 'responds with correct permissions' do
      expect(subject).to match_array roles[3].permissions
    end
  end
end
