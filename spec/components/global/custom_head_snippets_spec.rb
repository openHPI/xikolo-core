# frozen_string_literal: true

require 'spec_helper'

describe Global::CustomHeadSnippets, type: :component do
  subject(:component) { described_class.new }

  describe '#render' do
    context 'without config' do
      it 'does not render anything' do
        render_inline(component)
        expect(page.text).to be_empty
      end
    end

    context 'with two configured JS snippets' do
      before do
        xi_config <<~YML
          custom_html:
            - html: "<script>alert('hello')</script>"
            - html: "<script>alert('world')</script>"
        YML
      end

      it 'includes them both, without escaping HTML' do
        render_inline(component)
        expect(page).to have_css 'script', text: "alert('hello')", visible: :all
        expect(page).to have_css 'script', text: "alert('world')", visible: :all
      end
    end

    context 'with a snippet that requires a cookie consent' do
      before do
        xi_config <<~YML
          custom_html:
            - html: "<script>alert('hello world')</script>"
              requirements:
                - type: cookie_consent
                  name: ui_survey
        YML
      end

      context 'when the consent was not given' do
        it 'does not render anything' do
          render_inline(component)
          expect(page.text).to be_empty
        end
      end

      context 'when the consent was given' do
        before { vc_test_controller.view_context.cookies[:cookie_consents] = '["+ui_survey"]' }

        it 'renders the snippet' do
          render_inline(component)
          expect(page).to have_css 'script', text: "alert('hello world')", visible: :all
        end
      end

      context 'when another consent was given' do
        before { vc_test_controller.view_context.cookies[:cookie_consents] = '["+tracking_you_everywhere"]' }

        it 'does not render anything' do
          render_inline(component)
          expect(page.text).to be_empty
        end
      end

      context 'when the consent was declined' do
        before { vc_test_controller.view_context.cookies[:cookie_consents] = '["-ui_survey"]' }

        it 'does not render anything' do
          render_inline(component)
          expect(page.text).to be_empty
        end
      end
    end
  end
end
