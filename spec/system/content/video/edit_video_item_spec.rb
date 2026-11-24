# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Teacher edits a video item', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:video) { create(:video) }
  let(:item) do
    create(:'course_service/item',
      section:,
      content: video,
      title: 'WWW Introduction')
  end
  let(:user) { create(:'account_service/user') }

  before do
    xi_config <<~YML
      open_mode:
        enabled: false
        default_value: false
    YML

    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group:)
    item
    sign_in(user:)
    click_on('Learn')
    click_on course.title
    click_on 'Course Administration'
    click_on 'Structure & Content'
    find('.fa-pen-to-square').click
  end

  describe 'change the video title' do
    it 'updates the title and navigates to the item page' do
      fill_in 'Title', with: 'Edited Video Title'
      click_on 'Save item'

      expect(page).to have_current_path(%r{sections/.*/items/.*/edit})
      expect(page).to have_text 'The item was updated successfully.'

      click_on 'Save and show item'

      expect(page).to have_current_path(%r{/learn/#{course.course_code}/items/})
    end
  end

  describe 'add subtitles to the video' do
    it 'uploads subtitles and shows success message' do
      attach_file 'Subtitles',
        Rails.root.join('spec/fixtures/files/valid_en.vtt'),
        visible: :all
      click_on 'Save item'

      expect(page).to have_current_path(%r{sections/.*/items/.*/edit})
      expect(page).to have_text 'The item was updated successfully.'
    end
  end

  describe 'add an image to the description' do
    it 'uploads an image and shows it in the preview' do
      page.find('[contenteditable="true"]').click
      attach_file Rails.root.join('spec/fixtures/files/mercedes.png'),
        visible: :all, multiple: 'multiple'
      click_on 'Save item'

      expect(page).to have_current_path(%r{sections/.*/items/.*/edit})
      expect(page).to have_text 'The item was updated successfully.'
      expect(page).to have_markdown_editor 'Description', with: '(s3://'
      expect(page).to have_markdown_editor 'Description', with: 'mercedes.png)'

      page.find('[aria-label="Preview"]').click

      displayed_description = page.find('.toastui-editor-md-preview.active')
      expect(displayed_description).to have_css("img[src$='mercedes.png']")
    end
  end

  describe 'change streams' do
    let(:provider) { create(:video_provider, :vimeo) }

    before do
      create(:stream, title: "#{course.course_code}_internetworking_intro_pip", provider:)
      create(:stream, title: "#{course.course_code}_internetworking_intro_lecturer", provider:)
      create(:stream, title: "#{course.course_code}_internetworking_intro_slides", provider:)
    end

    it 'assigns streams and shows success message' do
      tom_select '_internetworking_intro_pip', from: 'Pip stream', search: true, clear: true
      tom_select '_internetworking_intro_lecturer', from: 'Lecturer stream', search: true, clear: true
      tom_select '_internetworking_intro_slides', from: 'Slides stream', search: true, clear: true
      click_on 'Save item'

      expect(page).to have_current_path(%r{sections/.*/items/.*/edit})
      expect(page).to have_text 'The item was updated successfully.'
    end
  end
end
