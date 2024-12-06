# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Spaces: List', type: :request do
  subject(:collab_spaces) { api.rel(:collab_spaces).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:params) { {} }

  it { is_expected.to respond_with :ok }

  it 'responds with a list' do
    create(:collab_space)
    expect(collab_spaces.size).to eq(1)
  end

  context 'filtering' do
    let(:course_id) { '00000001-3300-4444-9999-000000000076' }
    let(:current_user_id) { '00000001-3100-4444-9999-000000000076' }
    let(:joined_collab_space) { create(:collab_space, name: 'My Space', course_id:) }
    let!(:unjoined_collab_space) { create(:collab_space, name: 'Not My Space', course_id:) }
    let(:params) { {user_id: current_user_id, course_id:} }

    before do
      create(:membership, collab_space_id: joined_collab_space.id, user_id: current_user_id, status: 'regular')
    end

    context 'when requesting all collab spaces for a course' do
      it 'returns all collab spaces' do
        expect(CollabSpace.count).to eq(2)
        expect(collab_spaces.size).to eq(2)
        expect(collab_spaces.pluck('name')).to contain_exactly('My Space', 'Not My Space')
      end
    end

    context 'when requesting joined collab spaces for a course' do
      let(:params) { super().merge with_membership: 'true' }

      it 'returns joined collab spaces' do
        expect(collab_spaces.size).to eq(1)
        expect(collab_spaces.pluck('name')).to contain_exactly('My Space')
      end

      context 'when a collab space has a pending membership of the current user' do
        let(:pending_space) { create(:collab_space, name: 'Pending Membership Space', course_id:) }

        before { create(:membership, collab_space: pending_space, user_id: current_user_id, status: 'pending') }

        it 'returns collab spaces with pending memberships' do
          expect(CollabSpace.count).to eq(3)
          expect(collab_spaces.size).to eq(2)
          expect(collab_spaces.pluck('name')).to contain_exactly('Pending Membership Space', 'My Space')
        end
      end
    end

    context 'when requesting unjoined collab spaces for a course' do
      let(:params) { super().merge with_membership: 'false' }

      before { expect(CollabSpace.count).to eq(2) }

      it 'returns unjoined collab spaces' do
        expect(collab_spaces.size).to eq(1)
        expect(collab_spaces.pluck('name')).to contain_exactly('Not My Space')
      end

      context 'when a collab space has multiple members' do
        before { create_list(:membership, 2, collab_space: unjoined_collab_space) }

        it 'does not return the same collab space more than once' do
          expect(collab_spaces.size).to eq(1)
          expect(collab_spaces.pluck('name')).to contain_exactly('Not My Space')
        end
      end

      context 'when a joined collab space has other members than the current user' do
        before { create(:membership, collab_space: joined_collab_space) }

        it 'does not return the joined collab space' do
          expect(collab_spaces.size).to eq(1)
          expect(collab_spaces[0]['name']).to eq('Not My Space')
        end
      end
    end
  end

  context 'sorting' do
    before do
      create(:collab_space, name: 'Space B', created_at: 1.day.ago)
      create(:collab_space, name: 'Space A', created_at: Time.zone.now)
    end

    it 'orders the list by creation date' do
      expect(collab_spaces[0]['name']).to eq('Space B')
      expect(collab_spaces[1]['name']).to eq('Space A')
    end

    context 'by name' do
      let(:params) { super().merge sort: 'name' }

      it 'is ordered by name' do
        expect(collab_spaces[0]['name']).to eq('Space A')
        expect(collab_spaces[1]['name']).to eq('Space B')
      end
    end
  end
end
