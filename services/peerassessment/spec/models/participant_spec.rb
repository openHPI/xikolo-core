# frozen_string_literal: true

require 'spec_helper'

describe Participant, type: :model do
  subject { participant }

  let(:user_id) { SecureRandom.uuid }
  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:participant) { create(:participant, user_id:, peer_assessment_id: assessment.id) }
  let(:shared_submission) { create(:shared_submission, peer_assessment_id: assessment.id) }
  let!(:submission) { create(:submission, user_id:, shared_submission:) }

  describe 'validity' do
    let(:participant) { build(:participant, user_id:, peer_assessment_id: assessment.id) }

    it 'is valid' do
      expect(participant).to be_valid
    end

    it 'but it should not be valid without peer_assessment_id set' do
      participant.peer_assessment_id = nil
      expect(participant).not_to be_valid
    end

    context 'with user_id occurring multiple times in one peer assessment' do
      before { create(:participant, user_id:, peer_assessment_id: assessment.id) }

      it 'is valid' do
        expect(participant).not_to be_valid
      end
    end
  end

  describe 'can_receive_grade?' do
    # make sure the user is in the last step
    # or has completed the previous step if it is mandatory

    subject { participant.can_receive_grade? }

    let(:assessment) { create(:peer_assessment, :with_rubrics) }
    let(:shared_submission) { create(:shared_submission, peer_assessment: assessment) }
    let(:submission) { create(:submission, user_id:, shared_submission:) }

    let(:second_last_step) { create(:self_assessment, peer_assessment: assessment, optional:) }
    let(:optional) { false }

    before do
      assessment.steps << create(:assignment_submission, peer_assessment: assessment)
      assessment.steps << create(:training, peer_assessment: assessment)
      assessment.steps << create(:peer_grading, peer_assessment: assessment)
      assessment.steps << second_last_step
      assessment.steps << create(:results, peer_assessment: assessment)
    end

    context 'with mandatory second last step' do
      context 'completed' do
        before do
          create(
            :review,
            :as_submitted,
            user_id:,
            step: second_last_step,
            submission:
          )
        end

        it { is_expected.to be_truthy }
      end

      context 'uncompleted' do
        it { is_expected.to be_falsey }
      end
    end

    context 'with optional second last step' do
      let(:optional) { true }

      context 'with user having arrived in second last step' do
        before { participant.update current_step: second_last_step.id }

        it { is_expected.to be_truthy }
      end

      context 'with user being in another step' do
        it { is_expected.to be_falsey }
      end
    end

    context 'with user having arrived in last step' do
      before { participant.update current_step: assessment.steps.last.id }

      it { is_expected.to be_truthy }
    end
  end

  describe 'group_members' do
    subject { participant.group_members }

    context 'without group' do
      it { is_expected.to be_empty }
    end

    context 'with group' do
      let(:group) { create(:group) }

      let!(:other_participant) do
        create(:participant, group:)
      end

      before { participant.update group: }

      it { is_expected.to have(1).item }
      it { is_expected.to include other_participant }
    end
  end

  describe '#state_for' do
    subject { participant.state_for(step) }

    context 'the user has not started the assessment yet' do
      context 'for a first step' do
        let(:step) { assessment.steps.first }

        it { is_expected.to eq :open }

        context 'that is not yet available' do
          before do
            step.update unlock_date: 2.days.from_now
          end

          it { is_expected.to eq :locked }
        end

        context 'that is past its deadline' do
          before do
            # Use update_columns because we don't want any callbacks to be run
            step.update_columns deadline: 2.days.ago
          end

          it { is_expected.to eq :locked }
        end
      end

      context 'for any other step' do
        let(:step) { assessment.steps.third }

        it { is_expected.to eq :locked }
      end
    end

    context 'the user has started the assessment' do
      before do
        participant.update(
          current_step: current_step.id,
          completed: completed_steps.map(&:id),
          skipped: skipped_steps.map(&:id)
        )
      end

      let(:completed_steps) { [] }
      let(:skipped_steps) { [] }

      context 'for the current step' do
        let(:current_step) { step }
        let(:step) { assessment.steps.third }

        context 'that is open' do
          it { is_expected.to be :open }
        end

        context 'that has been completed' do
          before do
            allow_any_instance_of(step.class).to receive(:complete?).with(participant.user_id).and_return(true) # rubocop:disable RSpec/AnyInstance
          end

          it { is_expected.to eq :finished }
        end

        context 'that is not yet available' do
          before do
            step.update unlock_date: 2.days.from_now
          end

          it { is_expected.to eq :locked }
        end

        context 'that is past its deadline' do
          before do
            # Use update_columns because we don't want any callbacks to be run
            step.update_columns deadline: 2.days.ago
          end

          it { is_expected.to eq :locked }
        end
      end

      context 'for previous steps' do
        let(:step) { assessment.steps.second }
        let(:current_step) { assessment.steps.third }
        let(:completed_steps) { [assessment.steps.first, assessment.steps.second] }

        it { is_expected.to eq :finished }
      end

      context 'for the following step' do
        let(:step) { assessment.steps.third }
        let(:current_step) { assessment.steps.second }
        let(:completed_steps) { [assessment.steps.first] }

        context 'when the current step is optional' do
          before do
            current_step.update optional: true
          end

          it { is_expected.to eq :open }
        end

        context 'when the current step is finished' do
          before do
            allow_any_instance_of(current_step.class).to receive(:complete?).with(participant.user_id).and_return(true) # rubocop:disable RSpec/AnyInstance
          end

          it { is_expected.to eq :open }
        end
      end

      context 'for the last step' do
        let(:step) { assessment.steps.last }
        let(:current_step) { step }

        context 'when its deadline has passed' do
          before do
            step.update(deadline: 2.days.ago)
          end

          it { is_expected.to eq :finished }
        end
      end
    end
  end

  describe 'advance' do
    subject(:advance) do
      participant.advance nil
      participant.save!
    end

    context 'from first step' do
      before { participant.update! current_step: assessment.reload.steps.first.id }

      context 'without fulfilled criteria' do
        it 'does not advance' do
          expect { advance }.not_to change { participant.reload.current_step }
        end
      end

      context 'with fulfilled criteria' do
        before do
          allow_any_instance_of(Step).to receive(:complete?).with(any_args).and_return(true) # rubocop:disable RSpec/AnyInstance
        end

        it 'advances participant to next step' do
          expect { advance }.to change { participant.reload.current_step }
            .from(assessment.steps.first.id)
            .to(assessment.steps.second.id)
        end
      end
    end

    context 'with team peer assessment' do
      let(:group) { create(:group) }
      let(:group_member) { create(:participant, peer_assessment_id: assessment.id, group:) }

      before do
        assessment.update! is_team_assessment: true
        participant.update!(group:)
        group_member
      end

      context 'from start to assignment submission' do
        it 'advances the other group members' do
          expect { advance }.to change { group_member.reload.current_step }
            .from(nil)
            .to(assessment.steps.first.id)
        end
      end
    end
  end
end
