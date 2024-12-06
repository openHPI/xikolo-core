# frozen_string_literal: true

module LocaleSteps
  Given 'I change the language to German' do
    click_on 'English'
    click_on 'Deutsch'
    context.assign :locale, :de
  end

  Given 'the language is set to English' do
    find('button[aria-description="Choose Language"]').click
    within '[data-behaviour="menu-dropdown"]' do
      click_on 'English'
    end
  end
end

Gurke.config.include LocaleSteps
