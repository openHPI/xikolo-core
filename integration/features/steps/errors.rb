# frozen_string_literal: true

module FriendlyErrors
  Then 'I see a friendly 404 page' do
    expect(page).to have_content '404'
    expect(page).to have_content 'the page you are looking for could not be found'
  end
end

Gurke.config.include FriendlyErrors
