# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Channel', type: :system do
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user['id'], permissions: %w[course.channel.edit course.channel.index]
    Stub.request(:account, :get, "/users/#{user['id']}")
      .to_return Stub.json(user)
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/channels', query: hash_including({}))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
      .and_return Stub.json([])
  end

  it 'prefills the form on unprocessable channel data' do
    channel = build(
      :'course:channel',
      code: 'subset',
      name: 'My channel',
      title_translations: {'de' => 'Mein Channel', 'en' => 'My channel'},
      info_link: {
        'href' => {'en' => 'https://www.example.com/faq', 'de' => 'https://www.example.com/de/faq'},
        'label' => {'en' => 'Our FAQ', 'de' => 'Unsere FAQ'},
      }
    )
    Stub.request(:course, :get, '/channels/subset')
      .and_return Stub.json(channel)
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

    Stub.request(:course, :patch, "/channels/#{channel['id']}")
      .to_return Stub.json({
        'errors' => {'stage_visual_upload_id' => ['upload_error']},
      }, status: 422)

    click_link_or_button 'Update channel'

    expect(page).to have_content 'The channel was not updated.'
    expect(page).to have_content 'Your file upload could not be stored.'

    expect(page).to have_field('Code', with: 'subset')
    expect(page).to have_field('Name', with: 'My channel')
    expect(page).to have_markdown_editor('Description (in English)', with: 'English!')
    expect(page).to have_markdown_editor('Description (in German)', with: 'Deutsch')

    click_link_or_button 'Advanced settings'
    expect(page).to have_field('Info link URL (in English)', with: 'https://www.example.com/en/faq')
    expect(page).to have_field('Info link URL (in German)', with: 'https://www.example.com/de/faq')
    expect(page).to have_field('Info link label (in English)', with: 'The FAQ')
    expect(page).to have_field('Info link label (in German)', with: 'Unsere FAQ')

    fill_in 'Name (English)', with: 'My important channel'
    fill_in 'Name (German)', with: 'Mein wichtiger Channel'

    update_channel = Stub.request(:course, :patch, "/channels/#{channel['id']}")
      .to_return(status: 201)

    click_link_or_button 'Update channel'

    expect(page).to have_content 'The channel has been updated.'

    expect(
      update_channel.with(
        body: hash_including(
          'code' => 'subset',
          'title_translations' => {
            'de' => 'Mein wichtiger Channel',
            'en' => 'My important channel',
          },
          'public' => true,
          'stage_statement' => nil,
          'description' => {
            'en' => 'English!',
            'de' => 'Deutsch',
          },
          'info_link' => {
            'href' => {'en' => 'https://www.example.com/en/faq', 'de' => 'https://www.example.com/de/faq'},
            'label' => {'en' => 'The FAQ', 'de' => 'Unsere FAQ'},
          }
        )
      )
    ).to have_been_requested
    # We do not care what happens afterwards; the correct data was sent to
    # the backend service.
  end
end
