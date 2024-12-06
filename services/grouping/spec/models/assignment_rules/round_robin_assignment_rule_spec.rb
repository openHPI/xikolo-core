# frozen_string_literal: true

require 'spec_helper'

describe AssignmentRules::RoundRobinAssignmentRule do
  let!(:user_test) { create(:user_test_w_test_groups, :round_robin) }
  let(:assignment_rule) { user_test.assignment_rule }

  describe '#assign' do
    context 'with two groups' do
      let(:num_groups) { 2 }

      it 'cycles through the groups' do
        expect(
          Array.new(10) do
            assignment_rule.assign num_groups:
          end
        ).to eq [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
      end
    end

    context 'with four groups' do
      let(:num_groups) { 4 }

      it 'cycles through the groups' do
        expect(
          Array.new(10) do
            assignment_rule.assign num_groups:
          end
        ).to eq [0, 1, 2, 3, 0, 1, 2, 3, 0, 1]
      end
    end
  end
end
