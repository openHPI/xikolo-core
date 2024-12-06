# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial', type: :request do
  subject { json }

  let(:trial) { create(:trial, finished: false) }
  let(:params) { {} }

  describe 'GET index' do
    before { get '/trials', params: }

    context 'for user_test' do
      let(:params) { {identifier: trial.user_test.identifier} }

      its(:size) { is_expected.to eq 1 }

      it 'returns the trial' do
        expect(json.first['id']).to eq(trial.id)
      end

      context 'with active' do
        let(:params) { super().merge active: 'true' }

        context 'with active user test' do
          its(:size) { is_expected.to eq 1 }
        end

        context 'finished user test' do
          let(:trial) do
            super().tap do |trial|
              trial.user_test.update! end_date: 2.days.ago
            end
          end
          let(:params) { super().merge active: 'true' }

          its(:size) { is_expected.to eq 0 }
        end

        context 'with non-existent identifier' do
          let(:params) { super().merge identifier: 'non-existent' }

          its(:size) { is_expected.to eq 0 }
        end
      end
    end
  end

  describe 'PATCH' do
    context 'set finished' do
      let(:action) { patch "/trials/#{trial.id}", params: {finished: true} }

      it 'updates the trial' do
        action
        expect(trial.reload.finished).to be true
      end

      it "increases the user_test's finish count" do
        expect { action }.to change { trial.user_test.finished_count }.by(1)
      end

      it "increases the test group's finish count" do
        expect { action }.to change { trial.test_group.finished_count }.by(1)
      end

      context 'waiting metric' do
        let(:trial) { create(:test_group_w_trials).trials.find_by(finished: false) }
        let(:waiting_metric) { trial.user_test.metrics.find_by('wait_interval > 0') }

        it 'increases the test group\'s finish count' do
          trial.test_group.compute_statistics
          expect { action }.to change { trial.reload.test_group.waiting_count[waiting_metric.id] }.by(1)
        end
      end
    end
  end
end
