# frozen_string_literal: true

require 'spec_helper'

describe Account::Treatment, type: :model do
  subject(:treatment) { create(:treatment) }

  describe '#group' do
    it 'returns the correct group' do
      expect(treatment.group).to match an_object_having_attributes(
        name: "treatment.#{treatment.name}"
      )
    end
  end
end
