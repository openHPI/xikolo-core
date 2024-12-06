# frozen_string_literal: true

require 'spec_helper'

describe Certificate::OpenBadgeTemplate, type: :model do
  let(:course) { create(:course) }
  let(:template) { create(:open_badge_template, course:) }

  describe 'unique for course' do
    subject(:duplicate_template) do
      build(:open_badge_template, course:)
    end

    before { template }

    it 'does not allow two open badge templates for the same course' do
      expect(duplicate_template).not_to be_valid
    end
  end
end
