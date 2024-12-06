# frozen_string_literal: true

require 'spec_helper'

describe TrialsController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:valid_attributes) { build(:trial).attributes }
  let(:user_id) { '00000001-3100-4444-9999-000000000003' }

  describe 'GET index' do
    subject { response }

    let!(:trial) { create(:trial) }
    let(:params) { {} }
    let(:action) { get :index, params: }

    it 'renders all trials' do
      action
      expect(json.pluck('id')).to contain_exactly(trial.id)
    end

    context 'for user_test' do
      let!(:trial_2) { create(:trial) }
      let(:params) { {identifier: trial_2.user_test.identifier} }

      it 'renders all trials of user_test' do
        action
        expect(json.pluck('id')).to contain_exactly(trial_2.id)
      end
    end
  end

  describe 'GET show' do
    it 'renders the requested trial' do
      trial = create(:trial)
      get :show, params: {id: trial.to_param}
      expect(json['id']).to eq trial.id
    end
  end

  describe 'PUT update' do
    let!(:trial) { create(:trial) }

    describe 'with valid params' do
      it 'updates the requested trial' do
        expect do
          put :update, params: {id: trial.to_param, 'finished' => 'true'}
        end.to change { trial.reload.finished }.to(true)
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested trial' do
      trial = Trial.create! valid_attributes
      expect do
        delete :destroy, params: {id: trial.to_param}
      end.to change(Trial, :count).by(-1)
    end
  end
end
