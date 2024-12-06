# frozen_string_literal: true

require 'spec_helper'

describe RubricOption, type: :model do
  subject { rubric_option }

  let(:assessment)    { create(:peer_assessment, :with_steps) }
  let(:rubric)        { create(:rubric, peer_assessment: assessment) }
  let(:rubric_option) { create(:rubric_option, rubric:) }

  describe 'validity' do
    it 'is valid' do
      expect(rubric_option).to be_valid
    end

    it 'but it should not be valid without rubric_id set' do
      rubric_option.rubric_id = nil
      expect(rubric_option).not_to be_valid
    end
  end
end
