# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerDashboard::SectionProgress::Statistic, type: :component do
  subject(:component) do
    described_class.new(label:, values:, icon:)
  end

  let(:values) do
    {'max_points' => 26.0, 'submitted_points' => 13.0, 'total_exercises' => 4, 'graded_exercises' => 0, 'submitted_exercises' => 2}
  end
  let(:label) { 'Assignments' }
  let(:icon) { 'money-check-pen' }

  it 'shows information about the section statistics' do
    render_inline(component)

    expect(page).to have_content '50%Assignments13 of 26 points'
    expect(page).to have_content '2 of 4 taken'
  end

  context 'when there are no exercises available' do
    let(:values) { {'max_points' => 0, 'submitted_points' => 0, 'total_exercises' => nil} }

    it 'shows no points' do
      render_inline(component)

      expect(page).to have_content 'AssignmentsNo points'
    end
  end
end
