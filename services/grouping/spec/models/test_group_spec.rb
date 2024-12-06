# frozen_string_literal: true

require 'spec_helper'

describe TestGroup, type: :model do
  describe 'validation' do
    subject(:group) { user_test.test_groups.build(index: 0, flippers: ['new_pinboard']) }

    let!(:user_test) { create(:user_test) }

    it { is_expected.to accept_values_for(:flippers, [], ['abc'], %w[a b c]) }
    it { is_expected.not_to accept_values_for(:flippers, nil, [''], ['a', '']) }

    context 'when another test group already exists in the same test' do
      let!(:other_group) { create(:test_group, user_test:) }

      it 'can not have the same index as the existing group' do
        expect(group).not_to accept_values_for(:index, other_group.index)
      end

      it 'can not have the same set of flippers as the existing group' do
        expect(group).not_to accept_values_for(:flippers, other_group.flippers)
      end
    end

    context 'when another test group exists in another test' do
      let!(:other_group) { create(:test_group, user_test: create(:user_test)) }

      it "can have the same index as the other test's existing group" do
        expect(group).to accept_values_for(:index, other_group.index)
      end

      it "can have the same set of flippers as the other test's existing group" do
        expect(group).to accept_values_for(:flippers, other_group.flippers)
      end
    end
  end

  describe '#group_name' do
    subject { test_group.group_name }

    let(:experiment) { create(:user_test_w_test_groups, identifier: 'the_experiment') }
    let(:test_group) { experiment.test_groups.first }

    context 'for a global experiment' do
      it { is_expected.to eq 'grouping.the_experiment.0' }
    end

    context 'for a course-specific experiment' do
      let(:course_id) { SecureRandom.uuid }
      let(:course_code) { 'the_course' }

      let(:experiment) { create(:user_test_w_test_groups, identifier: 'the_experiment', course_id:) }

      before do
        Stub.request(
          :course, :get, "/courses/#{course_id}"
        ).to_return Stub.json({
          id: course_id,
          course_code:,
          context_id: SecureRandom.uuid,
        })
      end

      it { is_expected.to eq 'grouping.the_experiment.the_course.0' }
    end
  end

  describe 'results' do
    subject { test_group.reload }

    let(:test_group) { create(:user_test_w_waiting_metric_and_results_trials_waiting).test_groups.first }
    let(:metric) { nil }

    before do
      test_group.save
      test_group.compute_statistics(metric)
    end

    describe '#total_count' do
      subject { super().total_count }

      it { is_expected.to eq 10 }
    end

    describe '#finished_count' do
      subject { super().finished_count }

      it { is_expected.to eq 10 }
    end

    describe '#waiting_count' do
      subject { super().waiting_count }

      it { is_expected.to be_a Hash }
      its(:values) { is_expected.to contain_exactly(nil, 4) }
    end

    describe '#mean' do
      subject { super().mean }

      it { is_expected.to be_a Hash }
      its(:values) { is_expected.to contain_exactly(nil, 1) }
    end

    describe '#results' do
      subject { super().results }

      it { is_expected.to be_a Hash }
      its(:values) { is_expected.to contain_exactly([], [1] * 6) }
    end

    context 'for one metric' do
      let(:metric) { test_group.user_test.metrics.find_by(wait_interval: 0) }

      describe '#waiting_count' do
        subject { super().waiting_count[metric.id] }

        it { is_expected.to be_nil }
      end

      describe '#mean' do
        subject { super().mean[metric.id] }

        it { is_expected.to eq 1 }
      end

      describe '#results' do
        subject { super().results[metric.id] }

        it { is_expected.to eq [1] * 6 }
      end
    end

    context 'for finished' do
      let(:test_group) do
        create(:user_test_two_groups_finished).treatments.first
      end

      describe '#total_count' do
        subject { super().total_count }

        it { is_expected.to eq 8 }
      end

      describe '#finished_count' do
        subject { super().finished_count }

        it { is_expected.to eq 8 }
      end

      describe '#waiting_count' do
        subject { super().waiting_count }

        it { is_expected.to be_a Hash }
        its(:values) { is_expected.to contain_exactly(nil, 0) }
      end

      describe '#mean' do
        subject { super().mean }

        it { is_expected.to be_a Hash }
        its(:values) { is_expected.to contain_exactly(3.125, 3.375) }
      end

      describe '#results' do
        subject { super().results }

        it { is_expected.to be_a Hash }

        its(:values) do
          is_expected.to contain_exactly(
            a_collection_containing_exactly(2.0, 2.0, 2.0, 2.0, 2.0, 5.0, 5.0, 5.0),
            a_collection_containing_exactly(3.0, 3.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0)
          )
        end
      end

      describe '#change' do
        subject { super().change }

        it { is_expected.to be_a Hash }

        its(:values) do
          is_expected.to contain_exactly(
            a_value_within(0.01).of(-0.015625),
            a_value_within(0.01).of(0.28676)
          )
        end
      end

      describe '#confidence' do
        subject { super().confidence }

        it { is_expected.to be_a Hash }

        its(:values) do
          is_expected.to contain_exactly(
            a_value_within(0.00001).of(0.44969429247336323),
            a_value_within(0.00001).of(0.8433920747434539)
          )
        end
      end

      describe '#effect_size' do
        subject { super().effect }

        it { is_expected.to be_a Hash }

        its(:values) do
          is_expected.to contain_exactly(
            a_value_within(0.00001).of(0.07011395286642015),
            a_value_within(0.00001).of(0.5283199456688441)
          )
        end
      end

      describe '#required_participants' do
        subject { super().required_participants }

        it { is_expected.to be_a Hash }
        its(:values) { is_expected.to contain_exactly(2525, 47) }
      end

      describe '#box_plot_data' do
        subject { super().box_plot_data }

        it { is_expected.to be_a Hash }

        its(:values) do
          is_expected.to contain_exactly(
            a_collection_containing_exactly(2.0, 2.0, 2.0, 5.0, 5.0, []),
            a_collection_containing_exactly(3.0, 3.0, 3.0, 4.0, 4.0, [])
          )
        end
      end

      context 'for one metric' do
        let(:metric) { test_group.user_test.metrics.find_by(wait_interval: 0) }

        describe '#waiting_count' do
          subject { super().waiting_count[metric.id] }

          it { is_expected.to be_nil }
        end

        describe '#mean' do
          subject { super().mean[metric.id] }

          it { is_expected.to eq 3.125 }
        end

        describe '#results' do
          subject { super().results[metric.id] }

          it { is_expected.to contain_exactly(2.0, 2.0, 2.0, 2.0, 2.0, 5.0, 5.0, 5.0) }
        end

        describe '#change' do
          subject { super().change[metric.id] }

          it { is_expected.to be_within(0.01).of(0.28676) }
        end

        describe '#confidence' do
          subject { super().confidence[metric.id] }

          it { is_expected.to be_within(0.00001).of(0.8433920747434539) }
        end

        describe '#effect_size' do
          subject { super().effect[metric.id] }

          it { is_expected.to be_within(0.00001).of(0.5283199456688441) }
        end

        describe '#required_participants' do
          subject { super().required_participants[metric.id] }

          it { is_expected.to eq 47 }
        end

        describe '#box_plot_data' do
          subject { super().box_plot_data[metric.id] }

          it { is_expected.to eq [2.0, 2.0, 2.0, 5.0, 5.0, []] }
        end
      end
    end

    context 'without results' do
      let(:test_group) do
        create(:user_test_w_test_groups).treatments.first
      end

      describe '#box_plot_data' do
        subject { super().box_plot_data }

        it { is_expected.to be_a Hash }
        its(:values) { is_expected.to contain_exactly([0, 0, 0, 0, 0, []]) }
      end
    end
  end
end
