# frozen_string_literal: true

require 'spec_helper'

describe Course::Countdown, type: :component do
  subject(:component) { described_class.new(remaining_secs, **options) }

  let(:remaining_secs) { 300 }
  let(:options) { {} }

  it 'renders countdown targets and wiring' do
    render_inline(component)

    expect(page).to have_css(
      '[data-controller="countdown"]' \
      '[data-countdown-remaining-secs-value="300"]' \
      '[role="timer"]'
    )
    expect(page).to have_css('.x-countdown [data-countdown-target="minutes"]', text: '05')
    expect(page).to have_css('.x-countdown [data-countdown-target="seconds"]', text: '00')
    expect(page).to have_no_css('[data-countdown-target="hours"]')
  end

  context 'when remaining_secs is at least one hour' do
    let(:remaining_secs) { 3600 }

    it 'includes hours digit even without total_secs' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="hours"]', text: '01')
      expect(page).to have_css('[data-countdown-target="minutes"]', text: '00')
      expect(page).to have_css('[data-countdown-target="seconds"]', text: '00')
    end
  end

  context 'when remaining_secs is zero' do
    let(:remaining_secs) { 0 }

    it 'renders digits and omits hours' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="minutes"]', text: '00')
      expect(page).to have_css('[data-countdown-target="seconds"]', text: '00')
      expect(page).to have_no_css('[data-countdown-target="hours"]')
    end
  end

  context 'with total_secs' do
    let(:options) { {total_secs: 3600} }

    it 'includes hours digit' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="hours"]', text: '00')
      expect(page).to have_css('[data-countdown-target="minutes"]', text: '05')
      expect(page).to have_css('[data-countdown-target="seconds"]', text: '00')
    end
  end

  context 'with form selector' do
    let(:options) { {form: '#quiz-form'} }

    it 'sets submit-form value' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-submit-form-value="#quiz-form"]')
    end
  end

  context 'without form selector' do
    it 'omits submit-form value attribute' do
      render_inline(component)

      expect(page).to have_no_css('[data-countdown-submit-form-value]')
    end
  end

  context 'when remaining_secs is at least one day' do
    let(:remaining_secs) { (2.days + 3.hours + 5.minutes + 30.seconds).to_i }

    it 'includes days digits' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="days"]', text: '02')
      expect(page).to have_css('[data-countdown-target="hours"]', text: '03')
      expect(page).to have_css('[data-countdown-target="minutes"]', text: '05')
      expect(page).to have_css('[data-countdown-target="seconds"]', text: '30')
      expect(page).to have_no_css('[data-countdown-target="daysLabel"]')
    end
  end

  context 'with total_secs of at least one day' do
    let(:options) { {total_secs: 2.days.to_i} }

    it 'keeps days and hours digits when less time is left' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="days"]', text: '00')
      expect(page).to have_css('[data-countdown-target="hours"]', text: '00')
      expect(page).to have_css('[data-countdown-target="minutes"]', text: '05')
    end
  end

  context 'with the labeled variant' do
    let(:remaining_secs) { (2.days + 3.hours + 5.minutes + 30.seconds).to_i }
    let(:options) { {variant: :labeled} }

    it 'shows days, hours and minutes with unit labels' do
      render_inline(component)

      expect(page).to have_css('[data-countdown-target="days"]', text: '2')
      expect(page).to have_css('[data-countdown-target="daysLabel"]', exact_text: 'days', normalize_ws: true)
      expect(page).to have_css('[data-countdown-target="hours"]', text: '3')
      expect(page).to have_css('[data-countdown-target="minutes"]', text: '5')
      expect(page).to have_no_css('[data-countdown-target="seconds"]')
    end

    it 'hides the ticking numbers from screen readers' do
      render_inline(component)

      expect(page).to have_css('[aria-hidden="true"] [data-countdown-target="days"]')
    end

    context 'with a single unit each' do
      let(:remaining_secs) { (1.day + 1.hour + 1.minute).to_i }

      it 'uses the singular' do
        render_inline(component)

        expect(page).to have_css('[data-countdown-target="daysLabel"]', exact_text: 'day', normalize_ws: true)
        expect(page).to have_css('[data-countdown-target="hoursLabel"]', exact_text: 'hour', normalize_ws: true)
        expect(page).to have_css('[data-countdown-target="minutesLabel"]', exact_text: 'minute', normalize_ws: true)
      end
    end

    context 'with less than a day left' do
      let(:remaining_secs) { (3.hours + 5.minutes).to_i }

      it 'omits the days' do
        render_inline(component)

        expect(page).to have_no_css('[data-countdown-target="days"]')
        expect(page).to have_css('[data-countdown-target="hours"]', text: '3')
      end
    end
  end
end
