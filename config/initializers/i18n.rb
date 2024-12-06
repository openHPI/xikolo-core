# frozen_string_literal: true

require 'i18n'

I18n.enforce_available_locales = true

# Add branch specific locale file
# sitename must be used lowercase and . are replaced by _
Rails.application.config.tap do |config|
  config.i18n.load_path += Rails.root.glob("brand/#{Xikolo.config.brand}/locales/**/*.{rb,yml}").map(&:to_s)
end
