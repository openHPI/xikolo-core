# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Channel', type: :system do
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user['id'], permissions: %w[course.channel.create course.channel.index]
    Stub.request(:account, :get, "/users/#{user['id']}")
      .to_return Stub.json(user)
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/channels', query: hash_including({}))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
      .and_return Stub.json([])
  end

  def toggle(name)
    find('label', text: name).click
  end

  it 'prefills the form on unprocessable channel data' do
    visit '/channels/new'

    fill_in 'Code', with: 'subset'
    fill_in 'channel_name', with: 'Important subset of courses'
    fill_in 'Name (English)', with: 'Important subset of courses'
    fill_in 'Name (German)', with: 'Wichtige Teilmenge von Kursen'
    fill_markdown_editor 'Description (in English)', with: "Headline\n===\n\nenglish!"
    fill_markdown_editor 'Description (in German)', with: "Headline\n===\n\ngerman!"

    click_link_or_button 'Advanced settings'
    fill_in 'Info link URL (in English)', with: 'https://www.example.com/faq'
    fill_in 'Info link URL (in German)', with: 'https://www.example.com/de/faq'
    fill_in 'Info link label (in English)', with: 'Our FAQ'
    fill_in 'Info link label (in German)', with: 'Unsere FAQ'

    toggle 'Public'

    Stub.request(:course, :post, '/channels')
      .to_return Stub.json({
        'errors' => {'code' => ['upload_error', 'Custom Error message']},
      }, status: 422)

    click_link_or_button 'Add channel'

    expect(page).to have_content 'The channel was not created.'
    expect(page).to have_content 'Custom Error message'
    expect(page).to have_content 'Your file upload could not be stored.'

    expect(page).to have_field('Code', with: 'subset')
    expect(page).to have_field('Name (English)', with: 'Important subset of courses')
    expect(page).to have_field('Name (German)', with: 'Wichtige Teilmenge von Kursen')
    expect(page).to have_markdown_editor('Description (in English)', with: "Headline\n===\n\nenglish!")
    expect(page).to have_markdown_editor('Description (in German)', with: "Headline\n===\n\ngerman!")

    click_link_or_button 'Advanced settings'
    expect(page).to have_field('Info link URL (in English)', with: 'https://www.example.com/faq')
    expect(page).to have_field('Info link URL (in German)', with: 'https://www.example.com/de/faq')
    expect(page).to have_field('Info link label (in English)', with: 'Our FAQ')
    expect(page).to have_field('Info link label (in German)', with: 'Unsere FAQ')

    fill_in 'Name (English)', with: 'Adjusted important subset of courses'
    fill_in 'Name (German)', with: 'Angepasste wichtige Teilmenge von Kursen'

    create_channel = Stub.request(:course, :post, '/channels')
      .to_return(status: 201)

    click_link_or_button 'Add channel'

    expect(page).to have_content 'The channel has been created.'

    expect(
      create_channel.with(
        body: hash_including(
          'code' => 'subset',
          'name' => 'Important subset of courses',
          'title_translations' => {
            'en' => 'Adjusted important subset of courses',
            'de' => 'Angepasste wichtige Teilmenge von Kursen',
          },
          'public' => true,
          'stage_statement' => nil,
          'description' => {
            'en' => "Headline\n===\n\nenglish!",
            'de' => "Headline\n===\n\ngerman!",
          },
          'info_link' => {
            'href' => {'en' => 'https://www.example.com/faq', 'de' => 'https://www.example.com/de/faq'},
            'label' => {'en' => 'Our FAQ', 'de' => 'Unsere FAQ'},
          }
        )
      )
    ).to have_been_requested
  end
end
