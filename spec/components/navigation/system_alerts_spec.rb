# frozen_string_literal: true

require 'spec_helper'

describe Navigation::SystemAlerts, type: :component do
  subject(:component) do
    described_class.new(
      cookies: ActionDispatch::Cookies::CookieJar.build(
        ActionDispatch::Request.new(:test),
        cookies
      )
    )
  end

  let(:cookies) { {} }

  context 'with no current alerts' do
    it 'does not show alerts' do
      render_inline(component)

      expect(page.text).to be_empty
    end
  end

  context 'with current alerts' do
    let!(:old_published) do
      create(
        :alert, :published,
        publish_at: 3.days.ago,
        translations: {'en' => {'title' => 'Published old alert', 'text' => 'Text for old alert'}}
      )
    end
    let!(:recent_published) do
      create(
        :alert, :published,
        publish_at: 2.days.ago,
        translations: {'en' => {'title' => 'Published recent alert', 'text' => 'Text for recent alert with [link](https://www.example.com).'}}
      )
    end

    before do
      # Create some alerts that should not appear in the list
      create(:alert, :past)
      create(:alert, :future)
      create(:alert) # Draft
    end

    it 'shows all published alerts' do
      render_inline(component)

      expect(page).to have_css '[aria-label="Alerts"][aria-expanded="true"]'
      expect(page).to have_css '[role="status"]', count: 2, visible: :all
      expect(page).to have_content 'Published recent alert'
      expect(page).to have_content 'Text for old alert'
      expect(page).to have_content 'Published old alert'
      expect(page).to have_content 'Text for recent alert'
      expect(page).to have_link(text: 'link', href: 'https://www.example.com')
      expect(page).to have_no_content 'Some title'
    end

    context 'one of them seen already' do
      let(:cookies) { {seen_alerts: old_published.id} }

      it 'remembers seen alerts' do
        render_inline(component)

        expect(page).to have_css '[aria-label="Alerts"][aria-expanded="true"]'
        expect(page).to have_css '[role="status"]', count: 1
      end
    end

    describe '(localization)' do
      before do
        recent_published.translations['de'] = {'title' => 'Deutscher Titel', 'text' => 'Deutscher Text'}
        recent_published.save!
      end

      it 'returns the content for the platform default locale by default' do
        render_inline(component)

        expect(page).to have_content 'Published recent alert'
        expect(page).to have_content 'Published old alert'
        expect(page).to have_no_content 'Deutscher Titel'
      end

      context 'when requesting a specific language that is available' do
        it 'returns translated content where available, the platform default locale where not' do
          I18n.with_locale(:de) do
            render_inline(component)

            expect(page).to have_content 'Published old alert'
            expect(page).to have_content 'Deutscher Titel'
          end
        end
      end

      context 'when requesting only a language that is not available' do
        it 'returns the platform default locale content everywhere' do
          I18n.available_locales += [:it]
          I18n.with_locale(:it) do
            render_inline(component)

            expect(page).to have_content 'Published recent alert'
            expect(page).to have_content 'Published old alert'
            expect(page).to have_no_content 'Deutscher Titel'
          end
        end
      end
    end
  end
end
