# frozen_string_literal: true

require 'spec_helper'

describe StepsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:params) { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment_1) { create(:peer_assessment, :with_steps) }

  # And another peer assessment that should not interfere
  before { create(:peer_assessment, :with_steps) }

  describe '#index' do
    subject(:action) { get :index, params: }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all steps without additional parameters' do
      action
      expect(json.size).to eq(Step.all.size)
    end

    describe 'with a valid peer assessment id' do
      let(:additional_params) { {peer_assessment_id: peer_assessment_1.id} }

      it 'retrieves only steps belonging to this peer assessment' do
        action
        expect(json).not_to be_empty

        json.each do |item|
          expect(item['peer_assessment_id']).to eq peer_assessment_1.id # Don't try to access the hash with symbols here...
        end
      end
    end

    describe 'with an invalid peer assessment id' do
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
    subject(:action) { post :update, params: }

    describe 'with training step as target' do
      let(:training_step) { peer_assessment_1.steps[1] }
      let(:additional_params) { {id: training_step.id, training_opened: true} }

      it 'is not successful' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'with enough training samples' do
        before do
          # Fulfill requirements
          fulfill_training_requirements peer_assessment_1, training_step
        end

        it 'is successful' do
          action
          expect(response).to be_successful
        end

        it 'changes the open state of the training' do
          action
          expect(json['open']).to be(true)
        end
      end
    end

    describe 'with disallowed parameters' do
      let(:training_step) { peer_assessment_1.steps[1] }
      let(:additional_params) { {id: training_step.id, training_opened: false, peer_assessment_id: SecureRandom.uuid, deadline: 1.week.ago, position: -1, required_reviews: 10, optional: true, type: 'Random'} }
      let!(:step_decorator_json) { StepDecorator.new(training_step).as_json(api_version: 1) }

      it 'is successful' do
        action
        expect(response).to be_successful
      end

      it 'disregards disallowed parameters' do
        action

        expect(json['peer_assessment_id']).to eq(step_decorator_json['peer_assessment_id'])
        expect(json['position']).to eq(step_decorator_json['position'])
        expect(json['type']).to eq(step_decorator_json['type'])
      end

      it 'accepts allowed parameters' do
        action

        expect(json['required_reviews']).to eq(10)
      end
    end
  end
end
