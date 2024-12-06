# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerDashboard::SectionProgress::Score, type: :component do
  subject(:component) do
    described_class.new(label:, value:)
  end

  let(:value) { 60 }
  let(:label) { 'Graded' }

  it 'shows the overview information' do
    render_inline(component)

    expect(page).to have_content 'Graded60%'
  end

  context 'without score for this category, e.g. since there are no items or sections available' do
    let(:value) { nil }

    it 'shows no information but a dash instead' do
      render_inline(component)

      expect(page).to have_content 'Graded-'
    end
  end
end
