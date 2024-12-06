# frozen_string_literal: true

require 'spec_helper'

describe Lti::Gradebook, type: :model do
  describe '#submit' do
    subject(:submit) { gradebook.submit! score:, nonce: }

    let(:gradebook) { create(:lti_gradebook, exercise:) }
    let(:exercise) { create(:lti_exercise) }
    let(:score) { 0.75 }
    let(:nonce) { 'abcdef' }

    it 'stores the result in a new grade object' do
      expect { submit }.to change { exercise.score_for(gradebook.user_id) }.from(nil).to(0.75)
    end

    it 'schedules a worker to submit results to xi-course' do
      expect { submit }.to have_enqueued_job(Lti::PublishGradeJob).on_queue('default')
    end

    context 'with an invalid score' do
      let(:score) { 1.3 }

      it 'responds with an invalid, unpersisted record' do
        expect(submit.errors).not_to be_empty
        expect(submit).not_to be_persisted
      end

      it 'does not store the grade' do
        submit
        expect(exercise.score_for(gradebook.user_id)).to be_nil
      end

      it 'does not schedule a worker to submit results to xi-course' do
        expect { submit }.not_to have_enqueued_job(Lti::PublishGradeJob)
      end
    end

    context 'when the nonce has been used before' do
      before { create(:lti_grade, gradebook:, nonce:, value: 0.5) }

      it 'responds with an invalid, unpersisted record' do
        expect(submit.errors).not_to be_empty
        expect(submit).not_to be_persisted
      end

      it 'does not update the grade' do
        submit
        expect(exercise.score_for(gradebook.user_id)).to eq 0.5
      end

      it 'does not schedule a worker to submit results to xi-course' do
        expect { submit }.not_to have_enqueued_job(Lti::PublishGradeJob)
      end
    end

    context 'when the nonce has been used before, but in another gradebook' do
      before { create(:lti_grade, nonce:) }

      it 'stores the result in a new grade object' do
        expect { submit }.to change { exercise.score_for(gradebook.user_id) }.from(nil).to(0.75)
      end

      it 'schedules a worker to submit results to xi-course' do
        expect { submit }.to have_enqueued_job(Lti::PublishGradeJob).on_queue('default')
      end
    end
  end
end
