# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Student watches video', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:video) do
    create(:video, :dual_stream,
      description: 'Prof. Lena Babonsky introduces basic technical concepts of the World Wide Web from a users perspective.')
  end
  let(:item) do
    create(:'course_service/item',
      section:,
      content_type: 'video',
      content_id: video.id,
      title: 'WWW Introduction')
  end
  let(:user) { create(:'account_service/user') }

  before do
    item
    sign_in(user:)
    enroll_in(course)
  end

  it 'shows the video in the Xikolo dual stream player with its description' do
    visit "/learn/#{course.course_code}/items/#{item.id}"

    expect(page).to have_xpath '//xm-player[contains(@class, "hydrated")]'
    expect(page).to have_xpath '//xm-presentation[@name="dual"]', visible: :hidden
    within('.x-card .prose') do
      expect(page).to have_text \
        'Prof. Lena Babonsky introduces basic technical concepts of the World Wide Web from a users perspective.'
    end
  end

  context 'with an interactive transcript' do
    let(:video) { create(:video, :dual_stream, :with_subtitles) }

    it 'initializes the transcript and hides the loading spinner' do
      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_xpath '//xm-player[contains(@class, "hydrated")]'
      expect(page).to have_css '[data-transcript-loading][hidden]', visible: :all
    end
  end
end
