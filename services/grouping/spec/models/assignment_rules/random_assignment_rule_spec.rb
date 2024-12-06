# frozen_string_literal: true

require 'spec_helper'

describe AssignmentRules::RandomAssignmentRule do
  let!(:user_test) { create(:user_test_w_test_groups) }
  let(:assignment_rule) { user_test.assignment_rule }

  describe '#assign' do
    context 'with two groups' do
      let(:num_groups) { 2 }

      it 'assigns to the valid groups' do
        expect(
          Array.new(10) do
            assignment_rule.assign num_groups:
          end
        ).to all(be_a(Integer).and(satisfy {|val| val >= 0 && val <= 1 }))
      end
    end

    context 'with four groups' do
      let(:num_groups) { 4 }

      it 'assigns to the valid groups' do
        expect(
          Array.new(10) do
            assignment_rule.assign num_groups:
          end
        ).to all(be_a(Integer).and(satisfy {|val| val >= 0 && val <= 3 }))
      end
    end
  end
end
