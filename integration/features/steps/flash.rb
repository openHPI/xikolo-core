# frozen_string_literal: true

module FlashMessages
  Then(/there is a notice with "(.*)"/) do |text|
    expect(page).to have_notice text
  end
end

Gurke.config.include FlashMessages
