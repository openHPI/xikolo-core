# frozen_string_literal: true

module Global
  class CookieConsentBanner < ApplicationComponent
    private

    def render?
      consent.present?
    end

    def consent
      @consent ||= ConsentCookie.new(helpers.cookies).current
    end

    def text
      Translations.new(consent[:texts]).to_s
    end
  end
end
