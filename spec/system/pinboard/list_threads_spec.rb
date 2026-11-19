# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: List topics', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }

  before do
    sign_in(user: student)
    enroll_in(course)
  end

  it 'lists the first 25 topics ordered by creation time' do
    topics = Array.new(26) do |i|
      create(:'pinboard_service/question', course_id: course.id, title: "Topic #{format('%02d', i)}")
    end

    # Set timestamps sequentially. Default sort is updated_at DESC,
    # so Topic 00 (most recent) appears first on page 1.
    topics.each_with_index do |t, i|
      t.update_columns(created_at: i.minutes.ago, updated_at: i.minutes.ago)
    end

    click_on 'Forum'

    expect(page).to have_button('Start a new topic')

    # The newest 25 topics (0-24) should be on page 1; Topic 25 on page 2
    expect(page).to have_text('Topic 00')
    expect(page).to have_text('Topic 24')
    expect(page).to have_no_text('Topic 25')

    titles = all('.question-title').map(&:text)
    expect(titles.length).to eq(25)
    expect(titles.first).to eq('Topic 00')
    expect(titles.last).to eq('Topic 24')
  end

  it 'lists topics from second page' do
    topics = Array.new(26) do |i|
      create(:'pinboard_service/question', course_id: course.id, title: "Topic #{format('%02d', i)}")
    end

    topics.each_with_index do |t, i|
      t.update_columns(created_at: i.minutes.ago, updated_at: i.minutes.ago)
    end

    click_on 'Forum'

    within('.pinboard-pagination') do
      click_on '2'
    end

    expect(page).to have_text('Topic 25')
    expect(page).to have_no_text('Topic 00')
    expect(page).to have_button('Start a new topic')
  end

  it 'sorts topics by votes' do
    topic1 = create(:'pinboard_service/question', course_id: course.id, title: 'Topic Few Votes')
    topic2 = create(:'pinboard_service/question', course_id: course.id, title: 'Topic Many Votes')
    topic3 = create(:'pinboard_service/question', course_id: course.id, title: 'Topic Mid Votes')

    2.times { create(:'pinboard_service/vote', votable: topic1, value: 1) }
    10.times { create(:'pinboard_service/vote', votable: topic2, value: 1) }
    5.times { create(:'pinboard_service/vote', votable: topic3, value: 1) }

    click_on 'Forum'

    select 'Best voted first', from: 'Sort by'

    expect(page).to have_css('.question-title', count: 3)
    titles = all('.question-title').map(&:text)

    expect(titles[0]).to eq('Topic Many Votes')
    expect(titles[1]).to eq('Topic Mid Votes')
    expect(titles[2]).to eq('Topic Few Votes')
  end
end
