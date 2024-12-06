# frozen_string_literal: true

require 'spec_helper'

describe TrialResult, type: :model do
  describe 'scopes' do
    let!(:user_test) { create(:user_test_two_groups_finished) }

    before { create(:user_test_two_groups_finished) }

    describe '#for_user_test' do
      subject(:scoped) { described_class.for_user_test(user_test) }

      it 'contains only trial results belonging to the user test' do
        scoped.each do |trial_result|
          expect(trial_result.trial.user_test_id).to eq user_test.id
        end
      end
    end

    describe '#for_test_group' do
      subject(:scoped) { described_class.for_test_group(test_group) }

      let(:test_group) { user_test.test_groups.second }

      it 'contains only trial results belonging to the user test' do
        scoped.each do |trial_result|
          expect(trial_result.trial.test_group_id).to eq test_group.id
        end
      end
    end
  end

  describe '#csv_headers' do
    subject { described_class.csv_headers }

    it { is_expected.to eq 'id,waiting,result,created_at,updated_at,metric,user_id,test_group' }
  end

  describe '#to_csv' do
    subject { trial_result.to_csv }

    let(:trial_result) { create(:user_test_w_waiting_metric_and_results).trial_results.first }

    before { trial_result.update! result: 1.0 }

    it { is_expected.to eq "#{trial_result.id},false,1.0,#{trial_result.created_at.iso8601},#{trial_result.updated_at.iso8601},Enrollments,#{trial_result.trial.user_id},0" }
  end
end
