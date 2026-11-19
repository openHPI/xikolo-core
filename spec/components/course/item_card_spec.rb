# frozen_string_literal: true

require 'spec_helper'

describe Course::ItemCard, type: :component do
  subject(:component) { described_class.new(title: 'Final exam', label: 'Exam', icon: 'exam', **options) }

  let(:options) { {path: '/courses/digital-justice/items/abc'} }

  it 'links the title and type label to the item' do
    render_inline(component)

    expect(page).to have_link href: '/courses/digital-justice/items/abc', text: 'Final exam'
    expect(page).to have_css '.x-badge', text: 'Exam'
  end

  it 'does not prefetch the item on hover, as opening it counts as a visit' do
    render_inline(component)

    expect(page).to have_css 'a[data-turbo-prefetch="false"]', text: 'Final exam'
  end

  it 'is not marked as completed or locked by default' do
    render_inline(component)

    expect(page).to have_no_text 'Completed'
    expect(page).to have_no_text 'Locked'
  end

  context 'without a path' do
    let(:options) { {} }

    it 'is not a link' do
      render_inline(component)

      expect(page).to have_css '[data-testid="item-card"]', text: 'Final exam'
      expect(page).to have_no_link
    end
  end

  context 'when completed' do
    let(:options) { super().merge(state: :completed) }

    it 'marks the item as completed' do
      render_inline(component)

      expect(page).to have_link text: 'Completed'
    end
  end

  context 'when failed' do
    let(:options) { super().merge(state: :failed) }

    it 'marks the item as not passed' do
      render_inline(component)

      expect(page).to have_link href: '/courses/digital-justice/items/abc', text: 'Not passed'
      expect(page).to have_no_text 'Completed'
    end

    context 'with a call to action' do
      let(:options) { super().merge(action_label: 'Retake') }

      it 'shows the call to action and still tells the item was not passed' do
        render_inline(component)

        expect(page).to have_link href: '/courses/digital-justice/items/abc', text: 'Not passed'
        expect(page).to have_link text: 'Retake'
        expect(page).to have_no_css '[aria-current]'
      end
    end
  end

  context 'when locked' do
    let(:options) { super().merge(state: :locked) }

    it 'marks the item as locked and still links it' do
      render_inline(component)

      expect(page).to have_link href: '/courses/digital-justice/items/abc', text: 'Locked'
    end

    context 'without a path' do
      let(:options) { {state: :locked} }

      it 'marks the item as locked without linking it' do
        render_inline(component)

        expect(page).to have_css '[data-testid="item-card"]', text: 'Locked'
        expect(page).to have_no_link
      end
    end
  end

  context 'when current' do
    let(:options) { super().merge(state: :current, action_label: 'Continue') }

    it 'marks the item as the current step with its call to action' do
      render_inline(component)

      expect(page).to have_css 'a[aria-current="step"]', text: 'Final exam'
      expect(page).to have_link href: '/courses/digital-justice/items/abc', text: 'Continue'
      expect(page).to have_no_text 'Completed'
    end

    context 'without an action label' do
      let(:options) { super().except(:action_label) }

      it 'only marks the item as the current step' do
        render_inline(component)

        expect(page).to have_link 'Final exam', exact_text: true
        expect(page).to have_css 'a[aria-current="step"]'
      end
    end
  end

  it 'is not the current step by default' do
    render_inline(component)

    expect(page).to have_no_css '[aria-current]'
  end

  context 'with an unknown state' do
    let(:options) { {state: :in_progress} }

    it 'raises' do
      expect { component }.to raise_error ArgumentError, /Unknown state/
    end
  end
end
