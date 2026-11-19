# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Student reads rich text', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:richtext) { create(:'course_service/richtext', course:, text: '## Important information') }
  let(:item) do
    create(:'course_service/item',
      section:,
      content_type: 'rich_text',
      content_id: richtext.id,
      title: 'Reading material')
  end
  let(:user) { create(:'account_service/user') }

  before do
    item
    sign_in(user:)
    enroll_in(course)
  end

  it 'renders the rich text Markdown' do
    visit "/learn/#{course.course_code}/items/#{item.id}"

    within('.x-card .prose') do
      expect(page).to have_css('h2', text: 'Important information')
    end

    expect(page).to have_no_text 'Downloads'
  end

  context 'with reading material' do
    before do
      richtext.update!(reading_material_uri: 's3://xikolo-public/courses/materials/additional_reading.pdf')
    end

    it 'shows a download card for the reading material' do
      visit "/learn/#{course.course_code}/items/#{item.id}"

      within('section', text: 'Downloads') do
        expect(page).to have_css('h2', text: 'Downloads')
        expect(page).to have_text 'Reading material'
        expect(page).to have_text '.pdf'
        expect(page).to have_link(href: richtext.reading_material_url, download: true)
      end
    end
  end
end
