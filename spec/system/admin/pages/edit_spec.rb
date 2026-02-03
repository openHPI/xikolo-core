# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Page: Edit', type: :system do
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user['id'], permissions: %w[helpdesk.page.store]
    Stub.request(:account, :get, "/users/#{user['id']}")
      .and_return Stub.json(user)
  end

  it 'creates a new page' do
    visit '/pages/imprint'
    expect(page).to have_link('Add English translation')
    expect(page).to have_link('Add German translation')

    click_on 'Add English translation'

    fill_in 'Title', with: 'A very important imprint!'
    fill_markdown_editor 'Contents', with: 's3://invalid'

    click_on 'Save'

    expect(page).to have_content 'Referencing unknown files is not allowed'

    expect(page).to have_field 'Title', with: 'A very important imprint!'
    expect(page).to have_markdown_editor 'Contents', with: 's3://invalid'

    expect(Page.count).to eq 0

    fill_markdown_editor 'Contents', with: 'We should add an address ...'

    click_on 'Save'

    expect(page).to have_content 'A very important imprint!'
    expect(page).to have_content 'We should add an address ...'

    expect(Page.count).to eq 1
    Page.first.tap do |english_page|
      expect(english_page.text.to_s.strip).to eq 'We should add an address ...'
      expect(english_page).to have_attributes(
        'title' => 'A very important imprint!',
        'locale' => 'en'
      )
    end
  end

  it 'creates a new translation to an existing page' do
    create(:page, :english, name: 'imprint')

    visit '/pages/imprint'

    expect(page).to have_link('Edit English translation "English Title"')
    expect(page).to have_link('Add German translation')

    click_on 'Add German translation'

    fill_in 'Title', with: 'Ein wichtiges Impressum'
    fill_markdown_editor 'Contents', with: 's3://invalid'

    click_on 'Save'

    expect(page).to have_content 'Referencing unknown files is not allowed'

    expect(page).to have_field 'Title', with: 'Ein wichtiges Impressum'
    expect(page).to have_markdown_editor 'Contents', with: 's3://invalid'

    expect(Page.where(name: 'imprint').pluck(:locale)).to match_array %w[en]

    fill_markdown_editor 'Contents', with: 'Wir sollten eine Adresse hinzufügen ...'

    click_on 'Save'

    # Ensure translation has been saved
    expect(page).to have_content 'Edit German translation'

    expect(Page.where(name: 'imprint').pluck(:locale)).to match_array %w[en de]
    Page.find_by(name: 'imprint', locale: 'de').tap do |german_page|
      expect(german_page.title).to eq 'Ein wichtiges Impressum'
      expect(german_page.text.to_s.strip).to eq 'Wir sollten eine Adresse hinzufügen ...'
    end
  end

  it 'updates a translation' do
    english_page = create(:page, :english, name: 'imprint')

    visit '/pages/imprint'

    expect(page).to have_link 'Edit English translation "English Title"'
    expect(page).to have_link 'Add German translation'

    click_on 'Edit English translation "English Title"'

    expect(page).to have_field 'Title', with: 'English Title'
    expect(page).to have_markdown_editor 'Contents', with: 'English Text'

    fill_in 'Title', with: 'A very important imprint!'
    fill_markdown_editor 'Contents', with: 's3://invalid'

    click_on 'Save'

    expect(page).to have_content 'Referencing unknown files is not allowed'

    expect(page).to have_field 'Title', with: 'A very important imprint!'
    expect(page).to have_markdown_editor 'Contents', with: 's3://invalid'

    expect(english_page.reload.title).to eq 'English Title'

    fill_markdown_editor 'Contents', with: 'We should add an address ...'

    click_on 'Save'

    expect(page).to have_content 'A very important imprint!'
    expect(page).to have_content 'We should add an address ...'

    english_page.reload
    expect(english_page.title).to eq 'A very important imprint!'
    expect(english_page.text.to_s.strip).to eq 'We should add an address ...'
  end
end
