# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Channel', type: :system do
  before do
    sign_in(user: create(:'account_service/user', :admin))
  end

  it 'prefills the form on unprocessable channel data' do
    channel = create(
      :'course_service/channel',
      code: 'subset',
      description: {'de' => 'Deutsch!', 'en' => 'English!'},
      title_translations: {'de' => 'Mein Channel', 'en' => 'My channel'},
      info_link: {
        'href' => {'en' => 'https://www.example.com/faq', 'de' => 'https://www.example.com/de/faq'},
        'label' => {'en' => 'Our FAQ', 'de' => 'Unsere FAQ'},
      }
    )

    visit '/channels/subset/edit'

    expect(page).to have_field('Code', with: 'subset')
    expect(page).to have_field('Name (English)', with: 'My channel')
    expect(page).to have_field('Name (German)', with: 'Mein Channel')
    expect(page).to have_markdown_editor('Description (in English)', with: 'English!')
    expect(page).to have_markdown_editor('Description (in German)', with: 'Deutsch!')
    fill_markdown_editor 'Description (in German)', with: 'Deutsch'

    click_link_or_button 'Advanced settings'
    expect(page).to have_field('Info link URL (in English)', with: 'https://www.example.com/faq')
    expect(page).to have_field('Info link URL (in German)', with: 'https://www.example.com/de/faq')
    expect(page).to have_field('Info link label (in English)', with: 'Our FAQ')
    expect(page).to have_field('Info link label (in German)', with: 'Unsere FAQ')
    fill_in 'Info link URL (in English)', with: 'https://www.example.com/en/faq'
    fill_in 'Info link label (in English)', with: 'The FAQ'

    channel.save

    click_link_or_button 'Save'

    expect(page).to have_text 'The channel has been updated.'
  end
end
