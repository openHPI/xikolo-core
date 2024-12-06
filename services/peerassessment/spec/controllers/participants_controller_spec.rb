# frozen_string_literal: true

require 'spec_helper'

describe ParticipantsController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:json) { JSON.parse response.body }
  let(:params) { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }

  let!(:participant) do
    create(:participant,
      user_id:,
      peer_assessment:)
  end

  describe '#index' do
    subject(:action) { get :index, params: }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all additions' do
      action
      expect(json.size).to eq(Participant.all.size)
    end

    describe 'for a specific peer assessment' do
      let(:additional_params) { {peer_assessment_id: peer_assessment.id} }

      it 'includes the correct amount of user additions for this assessment' do
        action
        expect(json.size).to eq(peer_assessment.participants.count)
      end
    end
  end

  describe '#show' do
    subject(:action) { get :show, params: }

    describe 'with a valid user addition id' do
      let(:additional_params) { {id: participant.id} }

      it 'is successful' do
        action
        expect(response).to be_successful
      end

      it 'does not retrieve an array' do
        action
        expect(json.is_a?(Array)).to be(false)
      end

      it 'contains the requested id' do
        action
        expect(json['id']).to eq participant.id
      end
    end

    describe 'with an invalid id' do
      let(:invalid_id) { SecureRandom.uuid }
      let(:additional_params) { {id: invalid_id} }

      it 'returns nil' do
        action
        expect(json).to be_empty
      end

      it 'does not throw an exception' do
        action
        expect(response).not_to have_http_status :internal_server_error
      end
    end
  end

  describe '#create' do
    subject(:action) { post :create, params: }

    context 'with everything given in params to create a user adduition' do
      let(:additional_params) { {user_id: SecureRandom.uuid, peer_assessment_id: peer_assessment.id} }

      it 'is successful' do
        action
        expect(response).to be_successful
      end

      it 'creates a user addition' do
        expect { action }.to change { Participant.all.size }.by(1)
      end
    end

    context 'with missing parameters' do
      let(:additional_params) { {peer_assessment_id: peer_assessment.id} }

      it 'is not successful' do
        action
        expect(response).to be_client_error
      end

      it 'does not create a submission' do
        expect { action }.not_to change { Participant.all.size }
      end
    end
  end
end
