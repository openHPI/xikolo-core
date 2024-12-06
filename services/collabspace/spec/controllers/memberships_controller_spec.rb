# frozen_string_literal: true

require 'spec_helper'

describe MembershipsController, type: :controller do
  let!(:collab_space) { create(:collab_space) }
  let(:user_id) { '00000001-3100-4444-9999-000000000076' }
  let(:json) { JSON.parse response.body }
  let(:params) { {format: :json}.merge additional_params }
  let(:additional_params) { {} }

  before do
    Stub.service(
      :account,
      user_url: '/users/{id}'
    )

    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      id: user_id,
      display_name: 'Test User',
    })
  end

  describe '#create' do
    subject(:create_membership) { post :create, params: }

    let(:additional_params) do
      {collab_space_id: collab_space.id,
       user_id:,
       status:}
    end
    let(:status) { 'regular' }

    it 'adds a member to the specified collab_space' do
      expect { create_membership }.to change {
        CollabSpace.find(collab_space.id).memberships.size
      }.by(1)
    end

    it 'knows that the user is a member afterwards' do
      create_membership
      expect(collab_space.reload).to be_member user_id
    end

    describe 'pending membership' do
      let(:status) { 'pending' }

      it 'creates the right status' do
        create_membership
        expect(json['status']).to eq status
      end
    end
  end

  describe '#index' do
    subject(:list_memberships) { get :index, params: }

    it 'is successful' do
      list_memberships
      expect(response).to be_successful
    end

    it 'gets all memberships' do
      list_memberships
      expect(json.size).to eq(Membership.all.size)
    end

    describe 'for non existing course' do
      let(:additional_params) { {course_id: '00000001-3100-4444-9999-000000000099'} }

      before do
        create_list(:membership, 5)
      end

      it 'just gets the memberships from that course' do
        list_memberships
        expect(json.size).to eq(0)
      end
    end

    describe 'for teams' do
      let(:additional_params) { {kind: 'team'} }

      context 'without any team' do
        before { create_list(:membership, 5, collab_space:) }

        it 'does not return anything' do
          list_memberships
          expect(json).to have(0).items
        end
      end

      context 'with existing team' do
        let(:team) { create(:team) }

        before { create_list(:membership, 5, collab_space: team) }

        it 'returns the team members' do
          list_memberships
          expect(json).to have(6).items # 5 + owner
        end
      end
    end

    describe 'for one collab space' do
      let(:additional_params) { {collab_space_id: collab_space_2.id} }
      let(:collab_space_2) { create(:collab_space) }

      before do
        create_list(:membership, 5, collab_space_id: collab_space_2.id)
      end

      it 'just gets the users from that collab space' do
        list_memberships
        expect(json.size).to eq(collab_space_2.reload.memberships.size)
      end

      describe 'with an array of statuses' do
        let(:additional_params) do
          {collab_space_id: collab_space_2.id,
           status: {'0' => 'regular', '1' => 'admin'}}
        end

        it 'responds with all memberships' do
          create(
            :membership,
            collab_space_id: collab_space_2.id,
            status: 'admin'
          )

          list_memberships
          expect(json.size).to eq(collab_space_2.reload.memberships.size)
        end

        it 'does not include a pending membership if not specified' do
          create(
            :membership,
            collab_space_id: collab_space_2.id,
            status: 'pending'
          )

          list_memberships
          expect(json.size).to eq(collab_space_2.reload.memberships.size - 1)
        end
      end

      describe 'for an admin' do
        let(:additional_params) do
          {
            collab_space_id: collab_space_2.id,
            status: 'admin',
          }
        end

        before do
          create(
            :membership,
            collab_space_id: collab_space_2.id,
            status: 'admin'
          )
        end

        it 'responds with only the admin' do
          list_memberships
          # creator is also an admin
          expect(json.size).to eq(2)
        end

        it 'has the admin status' do
          list_memberships
          expect(json.first['status']).to eq 'admin'
        end

        it 'has fewer items than the total of memberships' do
          list_memberships
          expect(json.size).to be < collab_space_2.reload.memberships.size
        end
      end
    end

    describe 'for one user' do
      let(:additional_params) { {user_id:} }

      before do
        2.times do
          space = create(:collab_space)
          create(:membership, collab_space_id: space.id, user_id:)
        end
      end

      it 'returns only the colab spaces for that user' do
        list_memberships
        expect(json.size).to eq(2)
      end
    end
  end

  describe '#update' do
    let(:membership) { create(:membership, status: 'pending') }
    let(:additional_params) { {id: membership.id, status: 'regular'} }

    it 'can change the status to regular' do
      put(:update, params:)
      expect(membership.reload.status).to eq 'regular'
    end
  end

  describe '#destroy' do
    subject(:delete_mambership) { delete :destroy, params: {format: :json, id: membership.id} }

    let!(:membership) { create(:membership, user_id:) }

    it 'deletes the record' do
      delete_mambership
      expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'changes the number of memberships by one' do
      expect { delete_mambership }.to change { Membership.all.size }.by(-1)
    end
  end
end
