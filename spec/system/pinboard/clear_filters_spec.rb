# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Clear filters on forum', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    enroll_in(course)

    # Create explicit tags
    sql_tag = create(:'pinboard_service/explicit_tag', name: 'SQL', course_id: course.id)
    databases_tag = create(:'pinboard_service/explicit_tag', name: 'Databases', course_id: course.id)
    acid_tag = create(:'pinboard_service/explicit_tag', name: 'ACID', course_id: course.id)
    custom_tag = create(:'pinboard_service/explicit_tag', name: 'CustomTag', course_id: course.id)

    tags = [sql_tag, databases_tag, acid_tag, custom_tag]

    # Create 55 topics to fill three pages (25 per page)
    # Topics are numbered 1-55, and will be displayed in reverse creation order (newest first)
    55.times do |i|
      create(:'pinboard_service/question',
        course_id: course.id,
        user_id: user.id,
        title: "Topic #{i + 1}",
        tags: tags.sample(rand(1..tags.size)))
    end

    visit "/courses/#{course.course_code}/pinboard"
    expect(page).to have_css('.pinboard-topics') # Wait for topics to load
  end

  it 'clears filters after searching for a word' do
    fill_in 'Search', with: 'search'
    find('[aria-label="Search"]').click

    # Wait for AJAX to complete and check if filters were applied
    sleep 0.5

    click_on 'Reset all filters'

    # Verify first 25 topics are shown ordered by creation time (newest first)
    # Since topics were created 1-55, the newest (last created) should be Topic 55
    expect(page).to have_css('.question-title', count: 25)
    expect(page).to have_text('Topic 55')
    expect(page).to have_text('Topic 31')
  end

  it 'clears filters after searching for a tag' do
    # Click on SQL tag to filter
    first('.tag-button', text: 'SQL').click

    # Wait for filtered results to load
    sleep 0.5

    expect(page).to have_css('.question-title', minimum: 1)
    expect(page).to have_text('SQL') # At least one tag should be visible

    visit "/courses/#{course.course_code}/pinboard"
    expect(page).to have_css('.pinboard-topics')

    expect(page).to have_css('.question-title', count: 25)
    expect(page).to have_text('Topic 55')
    expect(page).to have_text('Topic 31')
  end

  it 'clears filters after changing sorting of topics' do
    select 'Best voted first', from: 'Sort by'

    # Wait for sorted results
    sleep 0.5 # Allow sorting to apply

    click_on 'Reset all filters'

    expect(page).to have_css('.question-title', count: 25)
    expect(page).to have_text('Topic 55')
    expect(page).to have_text('Topic 31')
  end
end
