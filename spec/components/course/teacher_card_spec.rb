# frozen_string_literal: true

require 'spec_helper'

describe Course::TeacherCard, type: :component do
  subject(:component) { described_class.new(name:, **options) }

  let(:name) { 'Ada Lovelace' }
  let(:options) { {} }

  it 'renders the name' do
    render_inline(component)

    expect(page).to have_text 'Ada Lovelace'
  end

  context 'with a picture' do
    let(:options) { {picture_url: 'https://s3.xikolo.de/xikolo-public/teachers/ada.jpg'} }

    it 'renders the picture as avatar' do
      render_inline(component)

      expect(page).to have_css '.x-avatar img[src*="ada.jpg"][alt=""]'
      expect(page).to have_no_css '.x-avatar-placeholder'
    end
  end

  context 'without a picture' do
    it 'renders an initials placeholder' do
      render_inline(component)

      expect(page).to have_css '.x-avatar.x-avatar-placeholder', text: 'AL'
      expect(page).to have_no_css '.x-avatar img'
    end

    context 'with a single-word name' do
      let(:name) { 'ada' }

      it 'uses the first letter' do
        render_inline(component)

        expect(page).to have_css '.x-avatar-placeholder', text: 'A'
      end
    end

    context 'with more than two names' do
      let(:name) { 'Ada King Lovelace' }

      it 'uses the first two initials' do
        render_inline(component)

        expect(page).to have_css '.x-avatar-placeholder', exact_text: 'AK', normalize_ws: true
      end
    end
  end

  context 'with a description' do
    let(:options) { {description: 'Hello **world** <script>alert(1)</script>'} }

    it 'renders sanitized markdown, clamped' do
      render_inline(component)

      expect(page).to have_css '[data-read-more-target="content"].line-clamp-4 strong', text: 'world'
      expect(page).to have_no_css 'script'
    end

    it 'renders a hidden, collapsed read-more toggle wired to the description' do
      render_inline(component)

      content_id = page.find('[data-read-more-target="content"]')[:id]
      expect(page).to have_css(
        "button[data-action='read-more#toggle'][aria-controls='#{content_id}'][aria-expanded='false'][hidden]",
        visible: :hidden
      )
      expect(page).to have_css '[data-read-more-target="moreLabel"]', text: 'more', visible: :hidden
      expect(page).to have_css '[data-read-more-target="lessLabel"][hidden]', text: 'less', visible: :hidden
    end
  end

  context 'without a description' do
    it 'renders no description or toggle' do
      render_inline(component)

      expect(page).to have_no_css '[data-controller="read-more"]'
    end
  end
end
