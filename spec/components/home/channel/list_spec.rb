# frozen_string_literal: true

require 'spec_helper'

describe Home::Channel::List, type: :component do
  subject(:component) { described_class.new(items:) }

  let(:item) { create(:'course_service/channel', :full_blown) }
  let(:items) { [item] }

  it 'renders a card with title, description and link for each item' do
    render_inline(component)

    expect(page).to have_css '.x-card', count: 1
    expect(page).to have_css '.x-card', text: 'Channel EN'
    expect(page).to have_css '.x-card', text: 'This is an awesome channel.'
    expect(page).to have_css ".x-card a[href='/channels/#{item.code}']"
  end

  context 'with a description only in another language' do
    let(:item) { create(:'course_service/channel', description: {de: 'Kanalbeschreibung'}) }

    it 'renders the fallback description' do
      render_inline(component)

      expect(page).to have_css '.x-card', text: 'Kanalbeschreibung'
    end
  end

  context 'without a description' do
    let(:item) { create(:'course_service/channel') }

    it 'renders an empty subtitle' do
      render_inline(component)

      subtitle = page.find('.x-card', text: 'Channel EN').all('.line-clamp-2').last
      expect(subtitle.text).to be_blank
    end
  end

  context 'with multiple items' do
    let(:items) { create_list(:'course_service/channel', 4) }

    it 'renders a card for each item' do
      render_inline(component)

      expect(page).to have_css '.x-card', count: 4
      items.each do |channel|
        expect(page).to have_css ".x-card a[href='/channels/#{channel.code}']"
      end
    end

    it 'alternates the tilt direction' do
      render_inline(component)

      expect(page).to have_css '.x-card.rotate-5', count: 2
      expect(page).to have_css '.x-card.-rotate-5', count: 2
    end

    it 'cycles the color scheme through primary, secondary and accent' do
      render_inline(component)

      expect(page).to have_css '.x-card.bg-primary-250', count: 2
      expect(page).to have_css '.x-card.bg-secondary-50', count: 1
      expect(page).to have_css '.x-card.bg-accent-50', count: 1
    end
  end

  context 'with no items' do
    let(:items) { [] }

    it 'renders nothing' do
      expect(component.render?).to be false
    end
  end
end
