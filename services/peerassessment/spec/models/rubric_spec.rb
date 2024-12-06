# frozen_string_literal: true

require 'spec_helper'

describe Rubric, type: :model do
  subject { rubric }

  let(:assessment) { create(:peer_assessment, :with_steps) }
  let(:rubric)     { create(:rubric, peer_assessment: assessment) }

  describe 'validity' do
    it 'is valid' do
      expect(rubric).to be_valid
    end

    it 'but it should not be valid without peer_assessment_id set' do
      rubric.peer_assessment_id = nil
      expect(rubric).not_to be_valid
    end

    it 'has no options' do
      expect(rubric.rubric_options).to be_empty
    end
  end
end
