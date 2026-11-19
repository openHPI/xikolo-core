# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Post a topic under a video', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:video) { create(:video) }
  let(:item) { create(:'course_service/item', section:, content_type: 'video', content_id: video.id) }
  let(:user) { create(:'account_service/user') }

  before do
    item
    sign_in(user:)
    enroll_in(course)
  end

  it 'starts a topic in a video context and lists it in reverse chronological order' do
    visit "/learn/#{course.course_code}/items/#{item.id}"

    find_by_id('show-topic-form').click
    fill_in 'Title', with: 'A Very (VERY) important question'
    fill_markdown_editor 'Text', with: 'I have no idea what to ask.'
    click_on 'Submit'

    within('.topic-list', visible: :all) do
      pending 'video.js dynamic adding of topis is not working'
      expect(page).to have_text 'A Very (VERY) important question'
    end

    find_by_id('show-topic-form').click
    fill_in 'Title', with: 'Second Question on Video'
    fill_markdown_editor 'Text', with: 'My even more stupid question'
    click_on 'Submit'

    within('.topic-list') do
      expect(page).to have_text 'Second Question on Video'
      expect(page.body.index('Second Question on Video'))
        .to be < page.body.index('A Very (VERY) important question')
    end
  end
end
