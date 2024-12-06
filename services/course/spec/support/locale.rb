# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    # Ensure default and current locale is always the same for each spec.
    I18n.default_locale = :en
    I18n.locale = :en
  end
end
