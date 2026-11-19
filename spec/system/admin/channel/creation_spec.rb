# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Channel', type: :system do
  let(:user) { create(:'account_service/user', :admin) }

  before do
    sign_in(user:)
  end

  def toggle(name)
    find('label', text: name).click
  end

  it 'prefills the form on unprocessable channel data' do
    visit '/channels/new'

    fill_in 'Code', with: 'subset'
    fill_in 'Name (English)', with: 'Important subset of courses'
    fill_in 'Name (German)', with: 'Wichtige Teilmenge von Kursen'
    fill_markdown_editor 'Description (in English)', with: "Headline\n===\n\nenglish!"
    fill_markdown_editor 'Description (in German)', with: "Headline\n===\n\ngerman!"

    click_link_or_button 'Advanced settings'
    fill_in 'Info link URL (in English)', with: 'https://www.example.com/faq'
    fill_in 'Info link URL (in German)', with: 'https://www.example.com/de/faq'
    fill_in 'Info link label (in English)', with: 'Our FAQ'
    fill_in 'Info link label (in German)', with: 'Unsere FAQ'

    expect(CourseService::Channel.count).to eq(0)

    toggle 'Public'

    click_link_or_button 'Save'

    expect(page).to have_text 'The channel has been created.'
    expect(CourseService::Channel.count).to eq(1)
  end
end
