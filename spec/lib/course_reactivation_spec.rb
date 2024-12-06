# frozen_string_literal: true

require 'spec_helper'

describe CourseReactivation do
  subject(:reactivation) { described_class }

  describe '#enabled?' do
    subject { reactivation.enabled? }

    # Disabled by default (esp. with vouchers being disabled).
    it { is_expected.to be false }

    context 'w/ default service configuration' do
      before do
        xi_config <<~YML
          voucher:
            enabled: true
        YML
      end

      it { is_expected.to be true }
    end

    context 'w/ missing service configuration' do
      before do
        # vouchers are enabled but course reactivation is not configured.
        xi_config <<~YML
          course_reactivation: {}
          voucher:
            enabled: true
        YML
      end

      it { is_expected.to be false }
    end
  end

  describe '#store_url' do
    subject(:url) { reactivation.store_url }

    context 'w/ one URL in the config' do
      before do
        xi_config <<~YML
          course_reactivation:
            store_url: https://www.shop.com
        YML
      end

      it 'returns the configured URL' do
        expect(url).to eq 'https://www.shop.com'
      end

      it 'returns the same URL for any language' do
        I18n.with_locale(:de) do
          expect(url).to eq 'https://www.shop.com'
        end
      end
    end

    context 'w/ a map of localized URLs in the config' do
      before do
        xi_config <<~YML
          course_reactivation:
            store_url:
              en: https://www.shop.com
              fr: https://www.shop.fr
        YML
      end

      it 'returns the configured URL based on the current locale' do
        expect(url).to eq 'https://www.shop.com'
      end

      it 'returns the configured URL for other languages' do
        I18n.with_locale(:fr) do
          expect(url).to eq 'https://www.shop.fr'
        end
      end

      it 'falls back to English for un-configured languages' do
        I18n.with_locale(:de) do
          expect(url).to eq 'https://www.shop.com'
        end
      end
    end
  end
end
