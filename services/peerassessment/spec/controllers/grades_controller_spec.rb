# frozen_string_literal: true

require 'spec_helper'

describe GradesController, type: :controller do
  let(:peer_assessment) { create(:peer_assessment, :with_steps) }
  let(:shared_submission) { create(:shared_submission, peer_assessment:) }
  let(:submissions) { create_list(:submission, 2, shared_submission:) }
  let(:grade) { submissions.first.grade }
  let(:team_grade) { submissions.second.grade }

  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }

  describe '#update' do
    subject(:action) { post :update, params: }

    let(:additional_params) { super().merge id: grade.id, delta: 1.0 }

    it 'updates the grade' do
      expect { action }.to change { grade.reload.delta }.to(1.0)
    end

    it 'does not update the other grade' do
      expect { action }.not_to change { team_grade.reload.delta }
    end

    context 'with is_team_grade param' do
      let(:additional_params) { super().merge is_team_grade: true }

      it 'updates the other grade' do
        expect { action }.to change { team_grade.reload.delta }.to(1.0)
      end
    end
  end
end
