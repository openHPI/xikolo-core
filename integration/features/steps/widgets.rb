# frozen_string_literal: true

module Steps::Widgets
  When(/I click on the "([\w ]+)" panel/) do |label|
    # The panel collapsing logic is initialized via JS. Sometimes, Capybara is
    # driving the browser faster than the browser can execute the JS, so we
    # give it a chance to initialize before trying to open the collapsed panel.
    sleep 0.2
    click_on label

    # And another sleep because the panel opens with a slow sliding animation.
    # This animation makes things move around on the page, which can cause
    # subsequent clicks to fail.
    sleep 0.2
  end

  When 'I click on submit' do
    click_on('Submit')
  end

  When 'I confirm' do
    click_on('Yes, sure')
  end

  Then(/I should see the "([\w ]+)" panel/) do |label|
    expect(page).to have_css('.panel-title', text: label)
  end
end

Gurke.config.include Steps::Widgets
