# frozen_string_literal: true

require 'spec_helper'

describe Course::Navigation, type: :component do
  subject(:component) { described_class.new(course_code: 'quantum', active:, locked:, forum:) }

  let(:active) { :details }
  let(:locked) { false }
  let(:forum) { true }

  context 'when enrolled' do
    it 'links all tabs' do
      render_inline(component)

      expect(page).to have_link 'Details', href: '/learn/quantum'
      expect(page).to have_link 'Forum', href: '/learn/quantum/pinboard'
      expect(page).to have_link 'Progress', href: '/learn/quantum/progress'
    end

    it 'links the announcements' do
      render_inline(component)

      expect(page).to have_link 'Announcements', href: '/learn/quantum/announcements'
    end

    it 'does not prefetch the announcements, as visiting them marks them as read' do
      render_inline(component)

      expect(page).to have_css('a[data-turbo-prefetch="false"]', text: 'Announcements')
    end

    it 'needs no unlock hint' do
      render_inline(component)

      expect(page).to have_no_css('[role="status"]', visible: :all)
      expect(page).to have_no_css('[data-controller="toast"]')
    end

    it 'marks the active tab as the current page' do
      render_inline(component)

      expect(page).to have_css('a[aria-current="page"]', text: 'Details')
      expect(page).to have_css('a[aria-current="page"]', count: 1)
    end

    context 'on the announcements page' do
      let(:active) { :announcements }

      it 'marks the announcements as the current page' do
        render_inline(component)

        expect(page).to have_css('a[aria-current="page"]', text: 'Announcements')
      end
    end
  end

  context 'when not enrolled' do
    let(:locked) { true }

    it 'keeps the course details accessible' do
      render_inline(component)

      expect(page).to have_link 'Details', href: '/learn/quantum'
    end

    it 'locks all other tabs and the announcements' do
      render_inline(component)

      expect(page).to have_no_link 'Forum'
      expect(page).to have_no_link 'Progress'
      expect(page).to have_no_link 'Announcements'
      expect(page).to have_css('button[aria-disabled="true"]', count: 3)
    end

    it 'explains how to unlock them' do
      render_inline(component)

      expect(page).to have_css('[role="status"]', text: 'Enroll in this course to unlock this feature.', visible: :all)
    end
  end

  context 'with unread announcements' do
    subject(:component) { described_class.new(course_code: 'quantum', active:, locked:, unread_announcements: 2) }

    it 'shows their number on the announcements button' do
      render_inline(component)

      expect(page).to have_css('.x-indicator-item', text: '2')
      expect(page).to have_link 'Announcements (2 unread)'
    end

    context 'on the announcements page' do
      let(:active) { :announcements }

      it 'shows no number' do
        render_inline(component)

        expect(page).to have_no_css('.x-indicator-item')
      end
    end
  end

  context 'with the recap' do
    subject(:component) { described_class.new(course_code: 'quantum', active:, locked:, recap_url: '/recap?course_id=1') }

    it 'links the recap tab' do
      render_inline(component)

      expect(page).to have_link 'Recap', href: '/recap?course_id=1'
    end

    context 'when not enrolled' do
      let(:locked) { true }

      it 'locks the recap tab' do
        render_inline(component)

        expect(page).to have_no_link 'Recap'
        expect(page).to have_css('button[aria-disabled="true"]', text: 'Recap')
      end
    end
  end

  it 'has no recap tab by default' do
    render_inline(component)

    expect(page).to have_no_text 'Recap'
  end

  context 'without the forum' do
    let(:forum) { false }

    it 'omits the forum tab' do
      render_inline(component)

      expect(page).to have_no_text 'Forum'
    end
  end
end
