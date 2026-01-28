# frozen_string_literal: true

require 'i18n'

I18n.enforce_available_locales = true

Rails.application.config.after_initialize do
  if Rails.env.development?
    require 'i18n-js/listen'
    # Generate frontend translations on-the-fly.
    I18nJS.listen
  end
end
