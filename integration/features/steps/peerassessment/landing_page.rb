# frozen_string_literal: true

module Steps::LandingPage
  When 'I accept the code of honor' do
    check 'I have read the code of honor'
  end

  When 'I start the assessment' do
    click_on 'Start'
  end

  Then 'there should be no start button' do
    expect(page).not_to have_content 'Start Peer Assessment'
  end

  Then 'I should see a request to accept the code of honor first' do
    expect(page).to have_content 'Please acknowledge the code of honour'
  end
end

Gurke.config.include Steps::LandingPage
