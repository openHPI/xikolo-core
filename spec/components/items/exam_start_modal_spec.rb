# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Items::ExamStartModal, type: :component do
  subject(:component) do
    described_class.new(
      id: 'item-1',
      start_path: '/new',
      pass_percentage: 70,
      displayed_max_points: 21,
      current_allowed_attempts: 2,
      current_time_limit_seconds: 3600
    )
  end

  it 'renders the exam start confirmation modal' do
    render_inline(component)

    expect(page).to have_text('Start exam?')
    expect(page).to have_text('Please note before starting:')
    expect(page).to have_text('The exam is passed with at least 70% of the points.')
    expect(page).to have_text('21 points')
    expect(page).to have_text('2 attempts')
    expect(page).to have_text('01:00:00')
    expect(page).to have_text('The timer keeps running even when you switch tabs.')
    expect(page).to have_link('Start exam', href: '/new')
    expect(page).to have_css('#start-exam-item-1')
  end

  context 'when there is no time limit' do
    subject(:component) do
      described_class.new(
        id: 'item-1',
        start_path: '/new',
        pass_percentage: 70,
        displayed_max_points: 21,
        current_allowed_attempts: 2,
        current_time_limit_seconds: nil
      )
    end

    it 'omits the time limit' do
      render_inline(component)

      expect(page).to have_no_text('01:00:00')
      expect(page).to have_no_text('00:00:00')
    end
  end
end
