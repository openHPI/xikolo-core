# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Manage richtext items', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:user) { create(:'account_service/user') }

  before do
    section
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)
    sign_in(user:)
  end

  it 'creates a richtext item' do
    visit "/learn/#{course.course_code}/sections"

    click_on 'Add item'

    select 'Text', from: 'Type'

    expect(page).to have_text 'Markup'
    expect(page).to have_text 'Drop files here or click to browse'

    fill_in 'Title', with: 'New Richtext Item'
    fill_markdown_editor 'Markup', with: 'Text for the richtext item'

    click_on 'Create Item'

    expect(page).to have_current_path("/learn/#{course.course_code}/sections")
    expect(page).to have_text 'New Richtext Item'
  end

  context 'with existing reading material' do
    let(:richtext) do
      create(:'course_service/richtext', course:,
        reading_material_uri: 's3://xikolo-public/reading_material.pdf')
    end
    let(:item) do
      create(:'course_service/item', section:,
        content: richtext)
    end

    before do
      visit "/learn/#{course.course_code}/sections/#{section.id}/items/#{item.id}/edit"
    end

    it 'keeps the reading material when saving the item' do
      click_on 'Save item'

      expect(page).to have_text 'The item was updated successfully.'
      expect(page).to have_link(href: richtext.reload.reading_material_url)
    end

    it 'removes the reading material with the remove button' do
      find('button[aria-label="Remove file"]').click

      expect(page).to have_text 'The item was updated successfully.'
      expect(page).to have_no_text 'reading_material.pdf'
      expect(richtext.reload.reading_material_uri).to be_nil
    end
  end
end
