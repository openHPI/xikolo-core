# frozen_string_literal: true

require 'spec_helper'

describe NoReviewsWorker, type: :worker do
  subject(:work) { NoReviewsWorker.new.perform(pa.id, grading_step.id) }

  before do
    3.times do |_|
      ss = create(:shared_submission, peer_assessment: pa)
      create(:submission, shared_submission: ss)
    end
  end

  let!(:pa) { create(:peer_assessment, :with_steps) }
  let!(:grading_step) { pa.grading_step }

  it 'does nothing' do
    expect { work }.not_to change(Conflict, :count)
  end

  context 'with completed grading step' do
    before { allow_any_instance_of(PeerGrading).to receive(:completion).and_return(1.0) } # rubocop:disable RSpec/AnyInstance

    it 'creates conflicts' do
      expect { work }.to change(Conflict, :count).by(3)
    end

    context 'with reviews' do
      let(:submission) { Submission.first } # pick any

      before do
        create(:review,
          :as_submitted,
          step_id: grading_step.id,
          submission_id: submission.id,
          user_id: SecureRandom.uuid)
      end

      it 'creates conflicts for unreviewed submissions' do
        expect { work }.to change(Conflict, :count).by(2)
      end
    end
  end
end
