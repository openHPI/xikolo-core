# frozen_string_literal: true

require 'spec_helper'

describe Quiz::Steps, type: :component do
  subject(:component) { described_class.new questions }

  let(:count) { 3 }
  let(:questions) do
    (1..count).map do |i|
      Struct.new(:id).new("question-#{i}")
    end
  end

  it 'renders one daisyUI step per question' do
    render_inline(component)

    expect(page).to have_css '#quiz-state-indicators.x-steps'
    expect(page).to have_css '#quiz-state-indicators .x-step', count: 3
  end

  it 'links each step to its question anchor with the indicator id' do
    render_inline(component)

    expect(page).to have_css '.x-step#question-1_indicator[href="#question-1"]'
    expect(page).to have_css '.x-step#question-2_indicator[href="#question-2"]'
    expect(page).to have_css '.x-step#question-3_indicator[href="#question-3"]'
  end

  it 'exposes the question number through the step aria-label' do
    render_inline(component)

    question = I18n.t('items.quiz.question')
    expect(page).to have_css(".x-step[aria-label='#{question} 1']")
    expect(page).to have_css(".x-step[aria-label='#{question} 2']")
    expect(page).to have_css(".x-step[aria-label='#{question} 3']")
  end

  context 'with a single question' do
    let(:count) { 1 }

    it 'renders a single step' do
      render_inline(component)

      expect(page).to have_css '.x-step', count: 1
    end
  end

  context 'with no questions' do
    let(:count) { 0 }

    it 'renders no steps' do
      render_inline(component)

      expect(page).to have_css '#quiz-state-indicators'
      expect(page).to have_no_css '.x-step'
    end
  end

  context 'with result statuses' do
    subject(:component) { described_class.new(questions, statuses:) }

    let(:statuses) { {'question-1' => 'correct', 'question-2' => 'incorrect'} }

    it 'applies the status class and mark to the matching steps' do
      render_inline(component)

      expect(page).to have_css '.x-step#question-1_indicator.x-step-success .x-step-icon'
      expect(page).to have_css '.x-step#question-2_indicator.x-step-error .x-step-icon'
    end

    it 'leaves steps without a status unmarked' do
      render_inline(component)

      step = page.find_css('.x-step#question-3_indicator')
      expect(step).to have_no_css '.x-step-success'
      expect(step).to have_no_css '.x-step-error'
      expect(step).to have_no_css '.x-step-icon'
    end
  end
end
