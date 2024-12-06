# frozen_string_literal: true

require 'spec_helper'

describe AssignmentRules::AssignmentRule do
  let(:assignment_rule) { described_class.new }
  let(:user_id) { SecureRandom.uuid }

  describe 'assign' do
    it 'assigns the default group' do
      expect(assignment_rule.assign).to eq 0
    end
  end
end
