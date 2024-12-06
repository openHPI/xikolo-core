# frozen_string_literal: true

require 'spec_helper'

describe GroupsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:action) { get :index }

    before { create_list(:group, 5) }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all groups' do
      action
      expect(json).to have(5).items
    end
  end

  describe '#show' do
    subject(:action) { get :show, params: {id: group.id} }

    let(:group) { create(:group) }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'contains the requested id' do
      action
      expect(json['id']).to eq group.id
    end

    describe 'with participants' do
      let(:group) { create(:group, :with_participants) }

      it 'contains participants' do
        action
        expect(json['participants']).to have(5).items
      end
    end
  end

  describe '#create' do
    subject(:action) { post :create, params: }

    let(:params) { {} }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    context 'with participants' do
      let(:participant_id) { SecureRandom.uuid }
      let(:params) { {participants: [participant_id]} }

      context 'with non existing participant' do
        it 'is not successful' do
          action
          expect(response).not_to be_successful
        end

        it 'does not create a group' do
          expect { action }.not_to change(Group, :count)
        end
      end

      context 'with existing participant' do
        before { create(:participant, id: participant_id) }

        it 'creates a group' do
          expect { action }.to change(Group, :count).by(1)
        end

        it 'assigns the participant' do
          action
          expect(json['participants']).to include a_hash_including('id' => participant_id)
        end
      end
    end
  end
end
