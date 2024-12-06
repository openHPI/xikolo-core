# frozen_string_literal: true

require 'spec_helper'

describe RubricsController, type: :controller do
  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment)  { create(:peer_assessment, :with_rubrics) }

  describe '#index' do
    subject(:action) { get :index, params: }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all rubrics' do
      action
      expect(json.size).to eq(Rubric.all.size)
    end

    describe 'for one specific peer assessment' do
      let(:additional_params) { {peer_assessment_id: peer_assessment.id} }

      it 'retrieves the correct amount of rubrics' do
        action
        expect(json.size).to eq(peer_assessment.rubrics.size)
      end
    end

    context 'with team_evaluation rubrics' do
      before { create(:rubric, peer_assessment:, team_evaluation: true) }

      it 'only returns normal rubrics' do
        action
        expect(json).to have(3).items
      end

      context 'with team_evaluation param' do
        let(:additional_params) { super().merge team_evaluation: true }

        it 'only returns team_evaluation rubrics' do
          action
          expect(json).to have(1).items
        end
      end
    end
  end
end
