# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerDashboard::CourseProgress, type: :component do
  subject(:component) do
    described_class.new(progresses, course)
  end

  let(:course) { create(:course) }
  let(:progresses) do
    [
      {
        'main_exercises' => {submitted_points: 20, max_points: 50},
        'bonus_exercises' => {submitted_points: 5, max_points: 10},
      },
    ]
  end

  it 'shows the overall graded points achieved' do
    render_inline(component)
    expect(page).to have_content('50%Graded points25 of 50')
  end

  it 'shows a tooltip with information on the bonus points' do
    render_inline(component)
    expect(page).to have_css("[data-tooltip='You got 20 points and earned 5 extra']")
  end

  context 'with a course that offers no bonus exercises' do
    let(:progresses) { [super().first.merge('bonus_exercises' => nil)] }

    it 'does not show the tooltip' do
      render_inline(component)
      expect(page).to have_content('40%Graded points20 of 50')
      expect(page).to have_no_css('[data-tooltip]')
    end
  end

  context 'with a course that offers bonus exercises but the user has not achieved any' do
    let(:progresses) { [super().first.merge('bonus_exercises' => {submitted_points: 0, max_points: 10})] }

    it 'does not show the tooltip' do
      render_inline(component)
      expect(page).to have_content('40%Graded points20 of 50')
      expect(page).to have_no_css('[data-tooltip]')
    end
  end
end
