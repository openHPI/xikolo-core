# frozen_string_literal: true

require 'spec_helper'

describe Footer::Main, type: :component do
  subject(:component) { described_class.new }

  describe '#render' do
    context 'configured not to be visible' do
      before do
        xi_config <<~YML
          footer:
            visible: false
        YML
      end

      it 'does not display the footer' do
        render_inline(component)

        expect(page).to have_no_selector('footer')
      end
    end

    context 'configured to be visible' do
      before do
        xi_config <<~YML
          footer:
            visible: true
        YML
      end

      it 'displays the footer' do
        render_inline(component)

        expect(page).to have_css('footer')
      end

      context 'configured with several columns of links' do
        before do
          xi_config <<~YML
            footer:
              visible: true
              columns:
                - headline: { en: 'More information' }
                  links:
                    - href: '/pages/about'
                      title: { en: 'About Us' }
                      text: { en: 'About Us' }
                - headline: { en: 'Help' }
                  links:
                    - href: '/pages/faq'
                      title: { en: 'FAQ' }
                      text: { en: 'FAQ' }
          YML
        end

        it 'displays the configured columns and links' do
          render_inline(component)

          expect(page).to have_content 'More information'
          expect(page).to have_link('About Us', href: '/pages/about')

          expect(page).to have_content 'Help'
          expect(page).to have_link('FAQ', href: '/pages/faq')
        end
      end

      context 'configured with social media links' do
        before do
          xi_config <<~YML
            footer:
              visible: true
              social_media:
                headline: { en: 'Follow us' }
                links:
                  - href: 'https://twitter.com/'
                    text: {en: 'Twitter'}
                    type: twitter
          YML
        end

        it 'displays the configured social media links' do
          render_inline(component)

          expect(page).to have_content 'Follow us'
          expect(page).to have_link('', href: 'https://twitter.com/')
          expect(page).to have_css('[title=Twitter]')
        end
      end

      context 'configured with an "About us" section' do
        before do
          xi_config <<~YML
            footer:
              visible: true
              about:
                headline: { en: 'About us' }
                description: { en: 'Xikolo is a great platform' }
          YML
        end

        it 'displays the configured "About us" section' do
          render_inline(component)

          expect(page).to have_content 'About us'
          expect(page).to have_content 'Xikolo is a great platform'
        end
      end

      context 'configured with a Newsletter section' do
        before do
          xi_config <<~YML
            footer:
              visible: true
              newsletter:
                headline: {en: 'Newsletter'}
                description: {en: 'Newsletter from Xikolo...'}
                link:
                  href: 'http://example'
                  text: {en: 'Register'}
          YML
        end

        it 'displays the configured Newsletter section' do
          render_inline(component)

          expect(page).to have_content 'Newsletter'
          expect(page).to have_link('Register', href: 'http://example')
        end
      end

      context 'configured with a Copyright section' do
        before do
          xi_config <<~YML
            footer:
              visible: true
              copyright:
                start_year: 2012
                owner:
                  href: {en: 'https://xikolo.de/en' }
                  title: {en: 'Owner' }
                  text: {en: 'Owner' }
                legal:
                  - href: '/pages/imprint'
                    title: { en: 'Imprint' }
                    text: { en: 'Imprint' }
                powered_by:
                  label: { en: 'Powered by' }
                  links:
                    - href: { en: 'https://xikolo.de/en' }
                      title: { en: 'Xikolo' }
                      text: { en: 'Xikolo' }
          YML
        end

        it 'displays the start year, owner, legal and powered_by infos' do
          render_inline(component)

          expect(page).to have_content '2012'
          expect(page).to have_link('Owner', href: 'https://xikolo.de/en')
          expect(page).to have_link('Imprint', href: '/pages/imprint')
          expect(page).to have_link('Xikolo', href: 'https://xikolo.de/en')
        end
      end
    end
  end
end
