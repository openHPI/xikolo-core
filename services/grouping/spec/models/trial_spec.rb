# frozen_string_literal: true

require 'spec_helper'

describe Trial, type: :model do
  let(:trial) { create(:trial) }
  let(:trial_result) { trial.reload.trial_results.first }
  let(:result) { 1 }

  before do
    allow(Metrics::EnrollmentsMetric).to receive(:query).and_return result
  end

  describe '#create_trial_results' do
    let(:trial) { build(:trial) }

    it 'creates create_trial_results' do
      expect { trial.save! }.to change(TrialResult, :count)
        .from(0).to(1)
    end
  end

  describe 'finishing' do
    it 'assigns a result' do
      trial.update! finished: true
      TrialResultWorker.perform_one

      expect(trial_result.result).to eq result
    end

    it 'updates finish_time' do
      trial.update! finished: true
      expect(trial.finish_time).not_to be_nil
    end

    context 'with waiting metric' do
      let(:trial) { create(:trial_with_waiting_metric) }
      let(:trial_result) { trial.reload.trial_results.find {|tr| tr.metric.delayed? } }

      it 'assigns a result' do
        trial.update! finished: true
        2.times { TrialResultWorker.perform_one }

        expect(trial_result.result).to eq result
      end

      it 'add a job' do
        expect { trial.update! finished: true }
          .to change { TrialResultWorker.jobs.size }.from(0).to(2)
      end

      it 'do not changes trial result waiting state if finished value is not changing' do
        expect(trial_result.waiting).to be false
        trial.update! finished: false

        expect(trial_result.waiting).to be false
      end

      it 'marks trial result as not waiting after fetching result' do
        trial.update! finished: true
        2.times { TrialResultWorker.perform_one }

        expect(trial_result.waiting).to be false
      end
    end
  end
end
