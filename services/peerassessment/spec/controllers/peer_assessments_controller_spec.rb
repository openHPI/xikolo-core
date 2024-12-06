# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessmentsController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment)  { create(:peer_assessment, :with_steps) }

  describe '#index' do
    subject(:action) { get :index, params: }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all assessments' do
      action
      expect(json.size).to eq(PeerAssessment.all.size)
    end
  end

  describe '#show' do
    subject(:action) { get :show, params: }

    describe 'with a valid assessment id' do
      let(:additional_params) { {id: peer_assessment.id} }

      it 'is successful' do
        action
        expect(response).to be_successful
      end

      it 'does not retrieve an array' do
        action
        expect(json.is_a?(Array)).to be false
      end

      it 'contains the requested peer assessment id' do
        action
        expect(json['id']).to eq peer_assessment.id
      end
    end

    describe 'with an invalid assessment id' do
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

  describe '#update' do
    subject(:action) { put :update, params: }

    let(:additional_params) { {id: peer_assessment.id, title: 'New Title'} }

    it 'does not delete the instructions via patch' do
      action
      expect(peer_assessment.reload.instructions).to eq 'These are some instructions'
    end
  end
end
