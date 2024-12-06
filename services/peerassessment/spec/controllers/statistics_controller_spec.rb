# frozen_string_literal: true

require 'spec_helper'

describe StatisticsController, type: :controller do
  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment)  { create(:peer_assessment, :with_steps) }

  describe '#show' do
    subject(:action) { get :show, params: }

    context 'training statistics' do
      let(:additional_params) { {peer_assessment_id: peer_assessment.id, concern: 'training'} }

      it 'succeeds' do
        action
        expect(response).to be_successful
      end

      it 'contains values for all training statistic fields' do
        action
        expect(json).not_to be_empty
      end

      context 'with no TA work done yet' do
        it 'contains default values' do
          action
          expect(json['required_reviews']).to eq(Training.required_ta_reviews)
          expect(json['finished_reviews']).to eq(0)
          expect(json['available_submissions']).to eq(Submission.all.size)
        end
      end

      context 'with some TA work done' do
        let(:shared_submission) { create(:shared_submission, :as_submitted, peer_assessment_id: peer_assessment.id) }
        let(:submission) { create(:submission, user_id: SecureRandom.uuid, shared_submission:) }

        before do
          create(:review, :as_train_review, :as_submitted,
            submission_id: submission.id,
            step: peer_assessment.steps[1],
            user_id: SecureRandom.uuid)
        end

        it 'returns the correct amount of train_done' do
          action
          expect(json['finished_reviews']).to eq(1)
        end
      end
    end
  end
end
